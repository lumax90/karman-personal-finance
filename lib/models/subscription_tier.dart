enum SubscriptionTier { free, premium }

enum AiModel { grok, gemini, openai }

extension AiModelX on AiModel {
  String get label {
    switch (this) {
      case AiModel.grok: return 'Grok';
      case AiModel.gemini: return 'Gemini';
      case AiModel.openai: return 'GPT-4o';
    }
  }

  String get provider {
    switch (this) {
      case AiModel.grok: return 'xAI';
      case AiModel.gemini: return 'Google';
      case AiModel.openai: return 'OpenAI';
    }
  }

  String get description {
    switch (this) {
      case AiModel.grok: return 'xAI Grok — Fast & creative';
      case AiModel.gemini: return 'Google Gemini — Balanced & smart';
      case AiModel.openai: return 'GPT-4o — Most capable';
    }
  }

  bool get isFreeAvailable => this == AiModel.grok;

  String get apiBaseUrl {
    switch (this) {
      case AiModel.grok: return 'https://api.x.ai/v1';
      case AiModel.gemini: return 'https://generativelanguage.googleapis.com/v1beta';
      case AiModel.openai: return 'https://api.openai.com/v1';
    }
  }

  String get defaultModelId {
    switch (this) {
      case AiModel.grok: return 'grok-3-mini-fast';
      case AiModel.gemini: return 'gemini-2.0-flash';
      case AiModel.openai: return 'gpt-4o-mini';
    }
  }
}
