import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../providers/auth_provider.dart';
import '../../../../features/operations/presentation/screens/main_menu_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider); // Tu estado real de autenticación
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. ESTRUCTURA EN CAPAS (Stack)
      body: Stack(
        children: [
          // CAPA 1: Fondo Fluido con CustomPainter (Bézier Cuadráticas y Cúbicas)
          Positioned.fill(
            child: CustomPaint(
              painter: _FluidBackgroundPainter(
                primaryColor: theme.colorScheme.primary,
                secondaryColor: Colors.deepOrange.shade300,
              ),
            ),
          ),
          
          // CAPA 2: Contenido interactivo y Lógica
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ANIMACIÓN VECTORIAL FLUIDA (Lottie)
                    SizedBox(
                      height: size.height * 0.25,
                      child: Lottie.network(
                        'https://lottie.host/80e14561-c852-45e3-99d9-299aedcb1395/kZ5nIrtG5z.json',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.inventory_2_rounded, size: 100, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Títulos
                    Text(
                      'SANGUI',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Gestión de Inventario JA-KAR',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                    ),
                    const SizedBox(height: 40),

                    // FORMULARIO (Glassmorphism integrado con tu lógica)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Campo de Usuario
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) => 
                                value != null && value.isNotEmpty ? null : 'Requerido',
                            ),
                            const SizedBox(height: 16),
                            
                            // Campo de Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscured,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(() => _isObscured = !_isObscured),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) => 
                                value != null && value.isNotEmpty ? null : 'Requerido',
                            ),
                            const SizedBox(height: 16),
                            
                            // Mensaje de Error (Lógica original)
                            if (authState.errorMessage != null) ...[
                              Text(
                                authState.errorMessage!, 
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Botón de Acción Principal
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: authState.isLoading ? null : _handleLogin,
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 24, width: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                      )
                                    : const Text(
                                        'INGRESAR',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                      ),
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
        ],
      ),
    );
  }
}

// ============================================================================
// MÓDULO DE DIBUJO VECTORIAL FLUIDO (CustomPainter)
// ============================================================================
class _FluidBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _FluidBackgroundPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = secondaryColor.withValues(alpha: 0.15);
    final topPath = Path();
    topPath.lineTo(0, size.height * 0.25);
    topPath.quadraticBezierTo(
      size.width * 0.25, size.height * 0.35, 
      size.width * 0.6, size.height * 0.20,
    );
    topPath.quadraticBezierTo(
      size.width * 0.85, size.height * 0.10, 
      size.width, size.height * 0.15,
    );
    topPath.lineTo(size.width, 0);
    topPath.close();
    canvas.drawPath(topPath, paint);

    paint.color = primaryColor.withValues(alpha: 0.1);
    final bottomPath1 = Path();
    bottomPath1.moveTo(0, size.height);
    bottomPath1.lineTo(0, size.height * 0.85);
    bottomPath1.cubicTo(
      size.width * 0.3, size.height * 0.75, 
      size.width * 0.7, size.height * 0.95, 
      size.width, size.height * 0.8,
    );
    bottomPath1.lineTo(size.width, size.height);
    bottomPath1.close();
    canvas.drawPath(bottomPath1, paint);

    paint.color = primaryColor.withValues(alpha: 0.05);
    final bottomPath2 = Path();
    bottomPath2.moveTo(0, size.height);
    bottomPath2.lineTo(0, size.height * 0.75);
    bottomPath2.cubicTo(
      size.width * 0.4, size.height * 0.9, 
      size.width * 0.6, size.height * 0.7, 
      size.width, size.height * 0.85,
    );
    bottomPath2.lineTo(size.width, size.height);
    bottomPath2.close();
    canvas.drawPath(bottomPath2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}