import 'package:cashflowiq/core/controllers/base_transaction_form_controller.dart';
import 'package:cashflowiq/core/theme/app_colors.dart';
import 'package:cashflowiq/core/theme/app_text_styles.dart';
import 'package:cashflowiq/core/widgets/step_indicator.dart';
import 'package:flutter/material.dart';

class BaseTransactionFormScreen extends StatelessWidget {
  final BaseTransactionFormController controller;
  final List<Widget> steps;
  final int totalSteps;
  final Color accentColor;
  final String submitLabel;
  final String nextLabel;
  final String backLabel;
  final VoidCallback? onNextStep;
  final Future<void> Function()? onSubmit;
  final Widget? loadingWidget;

  const BaseTransactionFormScreen({
    super.key,
    required this.controller,
    required this.steps,
    required this.totalSteps,
    this.accentColor = AppColors.error,
    this.submitLabel = 'Guardar',
    this.nextLabel = 'Siguiente',
    this.backLabel = 'Atrás',
    this.onNextStep,
    this.onSubmit,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoadingSources) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        return PopScope(
          canPop: controller.currentStep == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.prevStep(context);
          },
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: steps,
                ),
              ),
              StepIndicator(
                currentStep: controller.currentStep,
                totalSteps: totalSteps,
                activeColor: accentColor,
              ),
              _bottomBar(context),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomBar(BuildContext context) {
    final isLastStep = controller.currentStep == totalSteps - 1;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => controller.prevStep(context),
              child: Text(
                backLabel,
                style: AppTextStyles.subtitle2(context, color: accentColor),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: controller.isSaving
                  ? null
                  : (isLastStep ? onSubmit : onNextStep),
              child: controller.isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLastStep ? submitLabel : nextLabel,
                      style:
                          AppTextStyles.subtitle2(context, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
