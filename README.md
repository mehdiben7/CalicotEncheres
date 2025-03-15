# Défi Interuniversitaire en **Infrastructure as Code (IaC)** - Microsoft Azure

**Durée** : 3 heures  
**Équipes** : 2 personnes  
**Date** : 15 mars 2025

## Mise en situation

Après s'être être acheté une imprimante 3D pour suivre la tendance, M. Ken Oï a décidé de recréer la nostalgie de son enfance en imprimant des masques de Bionicle qu'il collectionnait en 2001. Il a rapidement réalisé qu'il n'était pas le seul à avoir ce désir, car plusieurs de ses amis lui ont demandé d'en faire pour eux aussi. Voyant que la demande était présente, il a décidé de créer une entreprise, **Calicot**, et a mis en place un site web marchand pour répondre à toute la demande.

Ce site a été conçu et déployé sur **Azure**. Cependant, Ken a configuré manuellement l'infrastructure via le portail Azure.

Avec le succès rapide du site, de nouveaux investisseurs ont rejoint l’entreprise. Ils ont rapidement remarqué l'absence d'automatisation dans le provisionnement de l’infrastructure, causant ainsi des erreurs lors des mises à jour ou de la création de nouveaux environnements (développement, acceptation, production).

**Calicot** fait appel à vous pour l’accompagner dans l’adoption de l’**Infrastructure as Code (IaC)**.

Votre mission est de créer les scripts nécessaires pour automatiser le déploiement de l'infrastructure actuelle de **Calicot**. Vous devrez choisir entre les technologies suivantes pour accomplir cette tâche :

- **Bicep**
- **Terraform**

Ces technologies ont été sélectionnées afin de faciliter le recrutement de talents pour soutenir la croissance de l'entreprise.

## Objectif du challenge

L'objectif est d'accompagner **Calicot** dans l’automatisation et l’optimisation de son infrastructure cloud sur **Azure** en utilisant l’**Infrastructure as Code (IaC)** et des pipelines **CI/CD** automatisés. Vous devrez donc déployer une infrastructure qui héberge l'**application web marchande** de Calicot, qui interagit avec une base de données **Azure SQL**. De plus, vous intégrerez un **Azure Blob Storage** existant et fourni par Calicot et qui contiendra les images des produits présentés par l'application web. La sécurité des données et des secrets, tels que la chaîne de connexion à la base de données, devra être gérée via **Azure Key Vault**.

Le diagramme de l'infrastructure Azure visée est le suivant :

![diagramme infrastructure Azure de Calicot](./img/CS-Games-IaC-2025.jpg)

💡 Calicot dispose déjà d'une équipe de développement dédiée à la mise à jour du code applicatif de son site web, vous n’avez donc qu’à vous concentrer sur la partie `Infrastructure as Code` (IaC) du projet.

## Tâches à réaliser

Pour débuter, faites un *fork* du référentiel <https://github.com/Cofomo/CalicotEncheres/tree/main> et ajoutez les comptes **alexis35115** et **Belrarr** comme collaborateurs à votre référentiel.

💡 **Un groupe de ressources, un code d'identification et un `Service Principal` seront attribués à chaque équipe.**

Vous aurez accès au portail Azure en **lecture seulement** afin de valider la création et la configuration des ressources que vous aurez déployé. Vous aurez aussi le droit d'ajouter le secret dans la Key Vault, tel que demandé à l'étape 4.

Notez que vous ne pouvez pas créer des ressources directement via le portail Azure car cela est contraire aux pratiques de gestion et de gouvernance des environnements infonuagiques adoptées par la majorité des entreprises.

Voici un aperçu des composants à mettre en place dans l'infrastructure :

### 1. **Provisionnement du réseau virtuel** :

- Créer un **Virtual Network (VNet)** nommé `vnet-dev-calicot-cc-{code d'identification}` avec deux sous-réseaux :
  - Un sous-réseau pour l'application web `snet-dev-web-cc-{code d'identification}` (**exposition publique sur internet autorisée via les ports HTTP et HTTPS**).
  - Un sous-réseau sécurisé pour la base de données `snet-dev-db-cc-{code d'identification}`.
  - **Région (location)** : Canada Central (pour toutes ces ressources)

### 2. **Déploiement de l'application web** :

- Créer une application web sur un **Azure App Service** :
  - **Tier** : Standard S1
  - **Nom de la ressource** : `app-calicot-dev-{code d'identification}`
  - **Région (location)** : Canada Central
- Configurer l'**auto-scaling** de l'application pour gérer des montées en charge :
  - **Scale out method** : automatique
  - **Condition** : le pourcentage moyen de CPU dépasse les 70%
  - **Maximum burst** : 2 instances
  - **Always ready instance** : 1 instance
  - **Enforce scale out limit** : oui
  - **Maximum scale limit** : 2
- Forcer les communications via HTTPS uniquement.
- Prévenir la mise en veille (*Always on*).
- Notez qu'une application web sur Azure App Service requiert un Azure App Service Plan. Celui-ci devra être nommé `plan-calicot-dev-{code d'identification}`.
- Ajoutez un `app settings` nommé `ImageUrl` ayant la valeur `https://stcalicotprod000.blob.core.windows.net/images/`.
- Configurez, pour cette application web, une identité managée assignée par le système.

### 3. **Création de la base de données** :

- Créer une **Azure SQL Database** :
  - **Tier** : Basic
  - **Nom de la ressource** : `sqldb-calicot-dev-{code d'identification}`
  - **Région (location)** : Canada Central
- Notez qu'une Azure SQL Database requiert une instance Azure SQL Server. Celle-ci devra être nommée `sqlsrv-calicot-dev-{code d'identification}`.

### 4. **Création de la Key Vault** :

- Créer une **Azure Key Vault**:
  - **Nom du Key Vault** : `kv-calicot-dev-{code d'identification}`
  - **SKU**: Standard
  - **Région (location)** : Canada Central
- Alimenter **manuellement** le secret contenant la chaîne de connexion à la de base de données via le portail Azure (vos droits d'accès vous permettent de le faire):
  - **Nom du secret** : `ConnectionStrings`
- Ajoutez ensuite, dans la web app, une entrée dans la section `Connection Strings` ayant comme valeur une référence à ce secret.
- Enfin, ajoutez un access policy sur la Key Vault afin que l'identité managée de l'application web puisse lire ce secret (permissions 'Get' et 'List').

### 5. **Automatisation via CI/CD** :

- Mettre en place un pipeline CI/CD avec **GitHub Actions** pour déployer l'infrastructure et automatiser la mise à jour de l'application.
  - Utiliser le **Service Principal** qui vous a été fourni pour l'authentification dans les workflows.
  - Les fichiers CI/CD doivent être placés sous `.github/workflows` de votre fork du dépôt GitHub.

#### Détails des workflows :

- **Déploiement de l'infrastructure** : (`iac.yml`)
  - Déclenchement **manuel**.
  - Doit inclure la création des ressources réseau, base de données, application web et la key vault.

- **Compilation et déploiement de l'application web** : (`build-deploy.yml`)
  - Déclenchement lors d’un `push` sur la branche `main`.

- **Alimenter la base de données** : (`db.yml`)
  - Déclenchement **manuel**.
  - Utiliser le fichier `Auctions_Data.bacpac` qui se trouve dans le répertoire `db`.

### 6. **Prise en charge de plusieurs environnements** :

Calicot vous lance un dernier défi : mettre en place un environnement d'acceptation (QA).

Votre mission sera d'extraire les valeurs des paramètres spécifiques à un environnement (comme les noms des ressources) dans un fichier de paramètres dédié, puis d'adapter votre processus de déploiement pour utiliser le fichier de paramètres correspondant à chaque environnement.

Adaptez la nomenclature des ressources en substituant `dev` par `qa`.

⚠️ **Notes importantes** :

1. Le déploiement de l'environnement d'acceptation est déclenché automatiquement après un déploiement réussi en `dev`. Calicot vous demande également d’utiliser le même groupe de ressources afin de simplifier la gestion et réduire la charge de travail.
2. Les ressources de l'environnement QA doivent également être déployées dans la région (location) `Canada Central`.

## Critères d'évaluation

Votre projet sera évalué selon les critères suivants :

- **Automatisation** : Les pipelines CI/CD doivent être entièrement fonctionnels.
- **Interaction de l'application** : L’application doit fonctionner correctement et afficher les informations attendues.
- **Sécurisation des secrets** : Les secrets doivent être stockés de manière sécurisée via **Azure Key Vault** et **GitHub Secrets**.
- **Respect des exigences** : Les ressources doivent respecter la nomenclature, le type et les configurations demandées.

## Conclusion

Ce défi vous permet de mettre en pratique les principes clés de l'automatisation, la sécurité et la scalabilité sur Azure. Il vous prépare à des scénarios réels en entreprise.

ajout pour ci cd yep