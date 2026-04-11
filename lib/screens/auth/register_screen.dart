import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    // Удаляем все нецифровые символы
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // Если начинается с 8, заменяем на 7
    if (digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    }
    
    // Если не начинается с 7, добавляем 7
    if (!digits.startsWith('7')) {
      digits = '7$digits';
    }
    
    return '+$digits';
  }

  String _formatPhoneInput(String value) {
    // Удаляем все нецифровые символы
    String digits = value.replaceAll(RegExp(r'\D'), '');
    
    // Ограничиваем 11 цифрами
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }
    
    // Если начинается с 8, заменяем на 7
    if (digits.startsWith('8')) {
      digits = '7${digits.substring(1)}';
    }
    
    // Если не начинается с 7, добавляем 7
    if (digits.isNotEmpty && !digits.startsWith('7')) {
      digits = '7$digits';
    }
    
    // Форматируем: +7 (XXX) XXX-XX-XX
    if (digits.isEmpty) return '';
    
    String formatted = '+7';
    
    if (digits.length > 1) {
      formatted += ' (${digits.substring(1, digits.length > 4 ? 4 : digits.length)}';
      if (digits.length >= 4) {
        formatted += ')';
      }
    }
    
    if (digits.length > 4) {
      formatted += ' ${digits.substring(4, digits.length > 7 ? 7 : digits.length)}';
    }
    
    if (digits.length > 7) {
      formatted += '-${digits.substring(7, digits.length > 9 ? 9 : digits.length)}';
    }
    
    if (digits.length > 9) {
      formatted += '-${digits.substring(9, 11)}';
    }
    
    return formatted;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _formatPhoneNumber(_phoneController.text.trim());
      final password = _passwordController.text;

      // Регистрация через Supabase Auth
      // Используем формат: phone@tasktracker.local
      final email = '${phone.replaceAll('+', '')}@tasktracker.local';

      print('📝 Регистрация: $email'); // Отладка
      print('📱 Телефон: $phone'); // Отладка

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'phone': phone,
          'name': name,
          'display_name': name,
        },
      );

      if (response.user != null && mounted) {
        print('✅ Регистрация успешна: ${response.user!.id}'); // Отладка
        print('📧 Email: ${response.user!.email}'); // Отладка
        
        // Показываем сообщение об успешной регистрации
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Регистрация успешна!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Небольшая задержка для обновления состояния
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Переходим на главный экран (EntryWrapper автоматически покажет MainScreen)
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.message}'); // Отладка
      if (mounted) {
        String message = 'Ошибка регистрации';
        if (e.message.contains('User already registered')) {
          message = 'Пользователь с таким номером уже зарегистрирован';
        } else if (e.message.contains('Password should be at least')) {
          message = 'Пароль должен быть не менее 6 символов';
        } else {
          message = 'Ошибка: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Ошибка: $e'); // Отладка
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6366F1).withValues(alpha: 0.1),
              const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Заголовок
                    Text(
                      'Регистрация',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Создайте новый аккаунт',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Поле имени
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Имя',
                        hintText: 'Введите ваше имя',
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF6366F1)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите имя';
                        }
                        if (value.trim().length < 2) {
                          return 'Имя слишком короткое';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Поле номера телефона
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Номер телефона',
                        hintText: '+7 (900) 123-45-67',
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF6366F1)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        final formatted = _formatPhoneInput(value);
                        if (formatted != value) {
                          _phoneController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите номер телефона';
                        }
                        final digits = value.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 11) {
                          return 'Номер телефона слишком короткий';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Поле пароля
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        hintText: 'Минимум 6 символов',
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFF6366F1)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен быть не менее 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Поле подтверждения пароля
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Подтвердите пароль',
                        hintText: 'Введите пароль еще раз',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6366F1)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Подтвердите пароль';
                        }
                        if (value != _passwordController.text) {
                          return 'Пароли не совпадают';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Кнопка регистрации
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Зарегистрироваться',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Кнопка возврата к входу
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Уже есть аккаунт? ',
                          style: TextStyle(color: Colors.grey[600]),
                          children: const [
                            TextSpan(
                              text: 'Войти',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
