// Chat with an AI tutor behind ChatService. Apps never hold the AI provider's key: the
// remote service talks to the app's own server (see Backend/dolingo-ai), which calls the model.
public enum TitanAIModule {
    public static let moduleName = "TitanAI"
}
