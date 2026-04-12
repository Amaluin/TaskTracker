import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phone = _formatPhoneNumber(_phoneController.text.trim());
      final password = _passwordController.text;

      // Вход через Supabase Auth с телефоном как email
      // Используем формат: phone@tasktracker.local
      final email = '${phone.replaceAll('+', '')}@tasktracker.local';

      print('🔐 Попытка входа: $email'); // Отладка

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && mounted) {
        print('✅ Вход успешен: ${response.user!.id}'); // Отладка
        
        // Показываем сообщение об успешном входе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вход выполнен!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        
        // Небольшая задержка для обновления состояния
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Возвращаемся на главный экран
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on AuthException catch (e) {
      print('❌ AuthException: ${e.message}'); // Отладка
      print('❌ Status: ${e.statusCode}'); // Отладка
      if (mounted) {
        String message = 'Ошибка входа';
        
        if (e.statusCode == '400') {
          message = 'Неверный формат запроса. Возможно, пользователь не подтвержден. Выполните SQL скрипт подтверждения.';
        } else if (e.message.contains('Invalid login credentials')) {
          message = 'Неверный номер телефона или пароль';
        } else if (e.message.contains('Email not confirmed')) {
          message = 'Email не подтвержден. Выполните SQL скрипт подтверждения.';
        } else {
          message = 'Ошибка: ${e.message} (код: ${e.statusCode})';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF5F7FA),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
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
                    // Иконка приложения
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        size: 80,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Заголовок
                    Text(
                      'Планировщик задач',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Войдите в свой аккаунт',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Поле номера телефона
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textCapitalization: TextCapitalization.none,
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
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        hintText: 'Введите пароль',
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Кнопка входа
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
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
                              'Войти',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Кнопка регистрации
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: RichText(
                        text: TextSpan(
                          text: 'Нет аккаунта? ',
                          style: TextStyle(color: Colors.grey[600]),
                          children: const [
                            TextSpan(
                              text: 'Зарегистрироваться',
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
    ),
    );
  }
}
