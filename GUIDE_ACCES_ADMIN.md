# 🚪 Guide d'Accès - Nouvelles Fonctionnalités Admin

## 📱 **Comment accéder aux nouvelles fonctionnalités**

### **1. Via le Menu Admin (Recommandé)**

1. **Connectez-vous** en tant qu'administrateur
2. **Ouvrez le menu** (icône hamburger ☰ en haut à gauche)
3. **Naviguez** vers les nouvelles sections :

#### 🔐 **Section "Sécurité & Monitoring"**
- 📜 **Logs d'audit** → Voir toutes les actions administratives
- 👥 **Permissions** → Gérer les rôles et permissions
- 📊 **Monitoring** → Surveillance système en temps réel

#### ⚙️ **Section "Configuration"** (existante)
- 🔧 **Paramètres** → Configuration de l'application
- 👤 **Mon profil** → Profil administrateur

---

### **2. Via URLs directes**

Vous pouvez aussi accéder directement via ces URLs :

```
🏠 Dashboard principal
/admin/dashboard

🔐 Nouvelles fonctionnalités
/admin/audit-logs      → Logs d'audit
/admin/permissions     → Gestion des permissions  
/admin/monitoring      → Monitoring système

📊 Fonctionnalités existantes
/admin/reservations    → Gestion des réservations
/admin/agents          → Gestion des agents
/admin/users           → Gestion des utilisateurs
/admin/statistics      → Statistiques
/admin/notifications   → Notifications
/admin/reports         → Rapports
/admin/settings        → Paramètres
```

---

## 🎯 **Fonctionnalités par écran**

### 📜 **Logs d'Audit** (`/admin/audit-logs`)
**Que faire ici :**
- ✅ Voir toutes les actions administratives
- ✅ Rechercher par admin, action, date
- ✅ Filtrer par type (agents, utilisateurs, etc.)
- ✅ Voir les détails des changements

**Exemple d'utilisation :**
1. Rechercher "delete" pour voir les suppressions
2. Filtrer par "agent" pour voir les modifications d'agents
3. Cliquer sur un log pour voir les détails

### 👥 **Gestion des Permissions** (`/admin/permissions`)
**Que faire ici :**
- ✅ Voir tous les utilisateurs et leurs rôles
- ✅ Modifier les permissions d'un utilisateur
- ✅ Assigner des rôles (Super Admin, Admin, Modérateur, Utilisateur)
- ✅ Gérer les permissions personnalisées

**Exemple d'utilisation :**
1. Rechercher un utilisateur par nom/email
2. Cliquer sur "Modifier" (icône crayon)
3. Changer le rôle ou ajuster les permissions
4. Sauvegarder

### 📊 **Monitoring Système** (`/admin/monitoring`)
**Que faire ici :**
- ✅ Voir l'état du système en temps réel
- ✅ Surveiller CPU, mémoire, disque
- ✅ Voir les alertes automatiques
- ✅ Monitorer les performances

**Exemple d'utilisation :**
1. Vérifier le statut général (vert = OK)
2. Surveiller les métriques système
3. Consulter les alertes récentes
4. Utiliser pause/play pour le monitoring

---

## 🔧 **Services Disponibles**

### **Pour les Développeurs :**

#### 1. **AuditService** - Traçabilité
```dart
// Enregistrer une action
await _auditService.logAdminAction(
  adminId: 'admin123',
  adminEmail: 'admin@example.com',
  action: 'update_agent',
  targetType: 'agent',
  targetId: 'agent456',
  oldData: {'name': 'Ancien nom'},
  newData: {'name': 'Nouveau nom'},
);
```

#### 2. **SecurityService** - Sécurité
```dart
// Vérifier une session
if (!securityService.isSessionActive) {
  // Rediriger vers login
}

// Vérifier les permissions
if (!securityService.hasPermission('delete_user')) {
  throw Exception('Permission insuffisante');
}
```

#### 3. **AdvancedReportService** - Rapports
```dart
// Générer un rapport
final report = await reportService.generateAgentPerformanceReport(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);
```

#### 4. **AdvancedNotificationService** - Notifications
```dart
// Envoyer une notification
await notificationService.sendAdminNotification(
  title: 'Maintenance',
  message: 'Maintenance programmée ce soir',
  targetType: 'all',
);
```

---

## 🚀 **Démarrage Rapide**

### **Première utilisation :**

1. **Connectez-vous** comme admin
2. **Allez dans "Logs d'audit"** pour voir l'historique
3. **Vérifiez "Monitoring"** pour l'état du système
4. **Configurez les permissions** selon vos besoins

### **Utilisation quotidienne :**

1. **Dashboard** → Vue d'ensemble
2. **Monitoring** → Vérifier la santé du système
3. **Logs d'audit** → Consulter les actions récentes
4. **Permissions** → Gérer les accès utilisateurs

---

## ⚠️ **Points Importants**

### **Sécurité :**
- 🔒 Les sessions expirent après **30 minutes** d'inactivité
- 🚫 **5 tentatives** de connexion max avant verrouillage
- 📝 Toutes les actions sont **automatiquement enregistrées**

### **Permissions :**
- 🔴 **Super Admin** : Accès complet (attention aux suppressions)
- 🔵 **Admin** : Gestion opérationnelle
- 🟠 **Modérateur** : Supervision limitée
- 🟢 **Utilisateur** : Accès standard

### **Monitoring :**
- 🟢 **Vert** : Système optimal
- 🟡 **Orange** : Attention requise
- 🔴 **Rouge** : Intervention nécessaire

---

## 🆘 **En cas de problème**

### **Erreurs courantes :**

1. **"Permission insuffisante"**
   - Vérifiez vos permissions dans `/admin/permissions`
   - Contactez un Super Admin

2. **"Session expirée"**
   - Reconnectez-vous
   - Les sessions durent 30 minutes

3. **"Erreur de chargement"**
   - Vérifiez votre connexion internet
   - Actualisez la page (F5)

### **Support :**
- 📧 Email : support@beeapp.com
- 📞 Téléphone : +225 01 02 03 04 05

---

## 🎉 **Félicitations !**

Vous avez maintenant accès à un système d'administration professionnel avec :
- ✅ Traçabilité complète des actions
- ✅ Sécurité renforcée
- ✅ Monitoring en temps réel
- ✅ Gestion granulaire des permissions

**Bonne administration !** 🚀
