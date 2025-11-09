public class Main {

    // Vulnerabilite intentionnelle : mot de passe en dur
    private static final String DB_PASSWORD = "secret123";

    public static void main(String[] args) {
        System.out.println("Application Java DevSecOps Demarree!");

        // Simulation d'une application simple
        if (args.length > 0) {
            String input = args[0];
            processInput(input);
        } else {
            showMenu();
        }
    }

    public static void showMenu() {
        System.out.println("\n=== MENU PRINCIPAL ===");
        System.out.println("1. Afficher la configuration");
        System.out.println("2. Traiter une requete");
        System.out.println("3. Quitter");

        // Simulation d'une vulnerabilite
        System.out.println("Debug - Mot de passe DB: " + DB_PASSWORD);
    }

    public static void processInput(String input) {
        // Vulnerabilite potentielle : pas de validation d'entree
        System.out.println("Traitement de: " + input);

        if (input.contains("SELECT") || input.contains("DROP")) {
            System.out.println("ALERTE - Requete SQL detectee: " + input);
        }

        // Simulation d'un traitement
        System.out.println("Traitement termine pour: " + input);
    }

    // Methode avec vulnerabilite intentionnelle
    public static String getConfig() {
        String apiKey = "sk-1234567890abcdef"; // Cle API exposee
        String dbUrl = "jdbc:mysql://localhost:3306/mydb?user=admin&password=admin123";

        return "API Key: " + apiKey + "\nDB URL: " + dbUrl;
    }
}