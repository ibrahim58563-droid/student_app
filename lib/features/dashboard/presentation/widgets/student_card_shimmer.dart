import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:students_app/core/constants/app_colors.dart';

class StudentCardShimmer extends StatelessWidget {
  const StudentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: Colors.white,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 120,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 10,
                width: double.infinity,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Container(
                height: 10,
                width: 160,
                alignment: Alignment.centerLeft,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}