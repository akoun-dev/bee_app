#!/bin/bash

# Script de déploiement sécurisé des index Firestore
# Ce script évite les conflits et déploie progressivement

echo "🚀 Déploiement sécurisé des index Firestore"
echo "=========================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
print_status() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier que Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI n'est pas installé"
    exit 1
fi

# Vérifier l'authentification
print_status "Vérification de l'authentification Firebase..."
if ! firebase projects:list &> /dev/null; then
    print_error "Vous n'êtes pas connecté à Firebase"
    echo "Exécutez: firebase login"
    exit 1
fi

print_success "Authentification OK"

# Sauvegarder le fichier actuel
print_status "Sauvegarde du fichier d'index actuel..."
if [ -f "firestore.indexes.json" ]; then
    cp firestore.indexes.json "firestore.indexes.backup.$(date +%Y%m%d_%H%M%S).json"
    print_success "Sauvegarde créée"
else
    print_warning "Aucun fichier d'index existant trouvé"
fi

# Utiliser le fichier minimal
print_status "Utilisation du fichier d'index minimal..."
cp firestore.indexes.minimal.json firestore.indexes.json

# Fonction pour déployer avec gestion d'erreurs
deploy_with_retry() {
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_status "Tentative de déploiement $attempt/$max_attempts..."
        
        # Déployer avec timeout
        if timeout 300 firebase deploy --only firestore:indexes --non-interactive; then
            print_success "Déploiement réussi !"
            return 0
        else
            local exit_code=$?
            print_warning "Tentative $attempt échouée (code: $exit_code)"
            
            if [ $attempt -lt $max_attempts ]; then
                print_status "Attente de 10 secondes avant la prochaine tentative..."
                sleep 10
            fi
        fi
        
        ((attempt++))
    done
    
    print_error "Échec du déploiement après $max_attempts tentatives"
    return 1
}

# Déployer les index
print_status "Déploiement des index Firestore..."
if deploy_with_retry; then
    print_success "Index déployés avec succès !"
    
    # Vérifier les index
    print_status "Vérification des index déployés..."
    firebase firestore:indexes 2>/dev/null || print_warning "Impossible de lister les index"
    
    # Tester une requête critique
    print_status "Les index sont en cours de construction..."
    print_warning "Cela peut prendre 15-45 minutes selon la taille de vos données"
    
    echo ""
    print_success "🎉 Déploiement terminé avec succès !"
    echo ""
    echo "📋 Prochaines étapes :"
    echo "1. Attendez que les index se construisent (15-45 min)"
    echo "2. Testez vos requêtes dans l'application"
    echo "3. Surveillez les logs pour vérifier qu'il n'y a plus d'erreurs"
    echo ""
    echo "🔍 Pour vérifier le statut des index :"
    echo "   firebase firestore:indexes"
    echo ""
    echo "🌐 Console Firebase :"
    echo "   https://console.firebase.google.com/project/zibene-f72fa/firestore/indexes"
    
else
    print_error "Échec du déploiement"
    
    # Restaurer le fichier de sauvegarde si disponible
    backup_file=$(ls -t firestore.indexes.backup.*.json 2>/dev/null | head -n1)
    if [ -n "$backup_file" ]; then
        print_status "Restauration du fichier de sauvegarde..."
        cp "$backup_file" firestore.indexes.json
        print_success "Fichier restauré"
    fi
    
    echo ""
    print_error "Solutions alternatives :"
    echo "1. Créer les index manuellement via la console Firebase"
    echo "2. Utiliser les liens directs des erreurs pour créer les index"
    echo "3. Contacter le support Firebase si le problème persiste"
    echo ""
    echo "🌐 Console Firebase :"
    echo "   https://console.firebase.google.com/project/zibene-f72fa/firestore/indexes"
    
    exit 1
fi

# Nettoyer les fichiers temporaires
print_status "Nettoyage..."
# Garder le fichier minimal pour référence future
# rm -f firestore.indexes.minimal.json

print_success "Script terminé !"
