import 'package:flutter/material.dart';
import 'dart:ui';

class GlowingTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final Color? focusColor;

  const GlowingTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.focusColor,
  });

  @override
  State<GlowingTextField> createState() => _GlowingTextFieldState();
}

class _GlowingTextFieldState extends State<GlowingTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _glowAnimation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _focusController,
        curve: Curves.easeInOut,
      ),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusController.forward();
      } else {
        _focusController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const glowColor = Color(0xFF00FFC6); // #00FFC6

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -2 * _glowAnimation.value), // Slight lift effect
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 20), // More top margin for label
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), // Slick top corner cut
                topRight: Radius.circular(4),  // Sharp top right
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              boxShadow: [
                // Outer glow
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.3 * _glowAnimation.value),
                  blurRadius: 20 * _glowAnimation.value,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), // Slick top corner cut
                topRight: Radius.circular(4),  // Sharp top right
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20), // Slick top corner cut
                      topRight: Radius.circular(4),  // Sharp top right
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    // Border now handled by TextField InputDecoration for label embracing
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        obscureText: widget.obscureText,
                        keyboardType: widget.keyboardType,
                        maxLines: widget.maxLines,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        decoration: InputDecoration(
                          labelText: null, // Hide default label, using custom embracing overlay
                          hintText: widget.hint,
                          filled: false,
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20), // Slick top corner cut
                              topRight: Radius.circular(4),  // Sharp top right
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                            borderSide: BorderSide(
                              color: _focusNode.hasFocus
                                  ? const Color(0xFF00FFC6) // Focused: emerald glow
                                  : const Color(0x0DFFFFFF), // Inactive: subtle white
                              width: 1,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20), // Slick top corner cut
                              topRight: Radius.circular(4),  // Sharp top right
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                            borderSide: BorderSide(
                              color: Color(0xFF00FFC6), // Focused: emerald glow
                              width: 2,
                            ),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20), // Slick top corner cut
                              topRight: Radius.circular(4),  // Sharp top right
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(14),
                            ),
                            borderSide: BorderSide(
                              color: Color(0x0DFFFFFF), // Inactive: subtle white
                              width: 1,
                            ),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          labelStyle: const TextStyle(
                            color: Colors.transparent, // Hide default label
                            fontSize: 0,
                          ),
                          hintStyle: const TextStyle(
                            color: Color(0x99FFFFFF), // rgba(255,255,255,0.6)
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                          ),
                          contentPadding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 24, // More top padding for label space
                            bottom: 20,
                          ),
                        ),
                      ),

                      // Futuristic embracing label overlay - always shown for futuristic effect
                      Positioned(
                        top: -8,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xE01E293B), // Semi-transparent dark background
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _focusNode.hasFocus
                                  ? const Color(0xFF00FFC6)
                                  : const Color(0x33FFFFFF),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_focusNode.hasFocus ? const Color(0xFF00FFC6) : Colors.transparent)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              color: _focusNode.hasFocus
                                  ? const Color(0xFF00FFC6)
                                  : const Color(0xFFE0E0E0),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}