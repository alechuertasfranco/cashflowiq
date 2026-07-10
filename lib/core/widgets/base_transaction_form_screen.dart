import 'package:cashflowiq/core/controllers/base_transaction_form_controller.dart';
import 'package:cashflowiq/core/theme/theme_extensions.dart';
import 'package:cashflowiq/core/widgets/app_buttons.dart';
import 'package:cashflowiq/core/widgets/step_indicator.dart';
import 'package:flutter/material.dart';

class BaseTransactionFormScreen extends StatelessWidget {
  final BaseTransactionFormController controller;
  final List<Widget> steps;
  final int totalSteps;
  final Color? accentColor;
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
    this.accentColor,
    this.submitLabel = 'Guardar',
    this.nextLabel = 'Siguiente',
    this.backLabel = 'Atrás',
    this.onNextStep,
    this.onSubmit,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAccentColor = accentColor ?? context.colorError;

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
                activeColor: resolvedAccentColor,
              ),
              _bottomBar(context, resolvedAccentColor),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomBar(BuildContext context, Color accentColor) {
    final isLastStep = controller.currentStep == totalSteps - 1;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: context.colorBackground,
        border: Border(top: BorderSide(color: context.colorBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: backLabel,
              color: accentColor,
              onPressed: () => controller.prevStep(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              label: isLastStep ? submitLabel : nextLabel,
              color: accentColor,
              isLoading: controller.isSaving,
              onPressed: isLastStep ? onSubmit : onNextStep,
            ),
          ),
        ],
      ),
    );
  }
}
