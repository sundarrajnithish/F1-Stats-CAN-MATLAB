# 🏎️ F1 Telemetry Data Acquisition and Analysis System

<div align="center">
  <button id="lang-toggle" onclick="toggleLanguage()" style="padding: 8px 16px; background-color: #333; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: bold;">
    Switch to French / Passer au français
  </button>
</div>

<div id="content-en">

A comprehensive platform for capturing, transmitting, visualizing, and analyzing Formula 1 telemetry data using Python, CAN bus communication, and MATLAB. This project demonstrates how to:

1. Extract real F1 telemetry data using FastF1 API
2. Transmit data over CAN bus
3. Visualize live telemetry data
4. Log and analyze driver performance metrics

## 🏆 System Overview

This project creates a complete end-to-end pipeline for working with F1 telemetry data:

![Architecture](/images/0.1.png)

- **Data Extraction**: Uses FastF1 Python API to access historical F1 race data
- **CAN Transmission**: Sends telemetry data over Vector virtual CAN bus
- **Real-time Visualization**: Multiple MATLAB scripts for live data display
- **Performance Analysis**: Tools to compare different drivers' telemetry
- **Data Logging**: Records all received data for post-session analysis

### Python CAN Transmission
![Python Code with CAN Transmission](/images/1.png)

## 🛠️ System Components

### 1. Data Transmission (`CAN_Send.py`)

The Python script extracts F1 telemetry from the 2023 Canadian Grand Prix and transmits it over CAN:
- Fetches fastest lap telemetry for 20 F1 drivers
- Packages telemetry data (speed, throttle, brake, gear, RPM) into CAN frames
- Transmits data over a Vector virtual CAN interface at configurable rates
- Includes error handling and progress tracking

### 2. CAN Message Format (`f1.dbc`)

Defines the CAN message structure for telemetry data:
- Message ID: 291 (0x123 in the code)
- Signal definitions:
  - Speed (km/h): 8-bit unsigned (0-255)
  - Throttle (%): 8-bit unsigned (0-100)
  - Brake (%): 8-bit unsigned (0-100)
  - Gear: 8-bit unsigned (0-15)
  - RPM: 16-bit unsigned (0-65535)

### 3. CAN Explorer Visualization
![CAN Explorer Visualization](/images/2.png)

### 4. MATLAB Data Reception (`CAN_Receive.m`)

Basic telemetry receiver that:
- Connects to Vector CAN channel
- Decodes incoming CAN messages
- Presents data in real-time multi-plot display
- Logs all data to timestamped CSV files

### 5. Performance Data Logger (`CAN_Receive_Performance.m`)

Enhanced receiver with:
- Automatic driver detection and separation
- Individual data logging for each driver
- Cleaner, more responsive visualization
- Organized data storage for analysis

### 6. MATLAB Real-time Visualization
![MATLAB Real-time Graphs](/images/3.png)

### 7. Driver Analysis Tool (`CAN_Driver_Analysis.m`)

Powerful comparison tool that:
- Loads any two driver telemetry logs
- Normalizes data by distance for fair comparison
- Generates side-by-side performance visualizations
- Helps identify driving style differences

### 8. Driver Performance Comparison
![Driver Comparison Analysis](/images/4.png)

### 9. Simulink Integration

Includes Simulink models for:
- Real-time data processing (`F1_Telemetry_Sim.slx`)
- Advanced signal filtering and analysis
- Custom visualization options
- Signal export capabilities
- Universal model with direct data simulation (`F1_Telemetry_Universal.slx`)

For this project, I created two distinct Simulink approaches:

1. **CAN-based Model** (`F1_Telemetry_Sim.slx`): Interfaces directly with Vector hardware for actual CAN bus communication. Ideal for situations where hardware is available and maximum realism is required.

2. **Universal Model** (`F1_Telemetry_Universal.slx`): Completely self-contained simulation that requires no additional hardware or toolboxes. This was my solution to the compatibility challenges that emerged when sharing the project with others who had different MATLAB configurations.

#### Universal Simulink Model
![Universal Simulink Model](/images/5.png)

The `F1_Telemetry_Universal` model represents a significant advancement in my approach to F1 telemetry visualization. During this project, I encountered numerous challenges with MATLAB version compatibility when implementing the CAN-based telemetry system. Many users were unable to run the original model due to specific Vector hardware dependencies and toolbox requirements that varied across MATLAB versions and licenses.

After spending weeks troubleshooting these compatibility issues, I developed this universal solution as a practical workaround that would function consistently across all environments. The key innovation was moving away from external hardware dependencies entirely.

Rather than relying on external CAN bus communications which required specific hardware and toolboxes, this model simulates the telemetry data directly within Simulink using fundamental blocks available in all MATLAB installations. My approach offers several advantages:

- **Universal Compatibility**: Works with any MATLAB version (from R2018b through R2023a tested) without requiring specialized toolboxes
- **Zero Hardware Dependencies**: Eliminates the need for Vector CAN hardware or drivers that many users don't have access to
- **Consistent Performance**: Delivers identical visualization experience across all systems, making it ideal for collaborative environments
- **Simplified Deployment**: Single-file solution that works immediately without complicated setup procedures
- **Realistic Data Patterns**: Despite being simulated, maintains the essential characteristics of actual F1 telemetry

The model architecture is elegantly simple yet effective. At its core, I implemented a system of sine wave generators with carefully calibrated parameters (frequency, amplitude, bias, and phase) to produce realistic F1 telemetry signals for speed, throttle, brake, and RPM. These signals are mathematically designed to mimic actual race data patterns while maintaining clean, predictable outputs for reliable analysis.

To enhance usability, I added a manual switch that allows seamless toggling between:
1. **Simulated Data Mode**: Using the internal sine wave generators for completely standalone operation
2. **External Data Mode**: For users who do have access to the necessary hardware to integrate real CAN data

The visualization components include custom-configured color-coded scopes (blue for speed, green for throttle, red for brake, and magenta for RPM) with appropriate scaling, numeric displays showing current values, and automatic workspace variable logging for post-simulation analysis. All data is synchronized using a common time base to maintain proper relationships between the telemetry channels.

For those interested in the technical implementation, the model:
- Uses a fixed-step solver with 0.1s step size for consistent data generation
- Employs signal converters with descriptive labels for improved readability
- Includes automatic data logging to workspace variables for further analysis
- Features carefully tuned scope configurations with appropriate Y-axis limits for each telemetry channel

The visualization components include color-coded scopes, numeric displays, and automatic workspace logging—all functioning identically to our hardware-dependent implementation but without the compatibility headaches.

Throughout my testing across multiple MATLAB versions and environments, I found this approach to be remarkably robust. Even with limited MATLAB licenses or older versions, the universal model performed consistently. This adaptability proved especially valuable when working with teams that had varying technical setups and access to hardware.

The design philosophy behind this model reflects my commitment to creating truly portable engineering solutions. While the CAN-based approach offers excellent real-world integration, the universal model demonstrates how clever use of fundamental building blocks can overcome practical limitations without sacrificing core functionality. This balance between technical sophistication and practical usability is something I strive to achieve in all my engineering projects.

## 📋 Requirements

### Python
- Python 3.9+
- `fastf1`: For F1 telemetry data access
- `python-can`: For CAN bus communication

Install with:
```bash
pip install fastf1 python-can
```

### MATLAB
For CAN-based implementation:
- MATLAB R2021a or newer recommended for full functionality
- Vehicle Network Toolbox (required for CAN communication)
- Simulink (required for visualization models)
- Vector CAN drivers (for hardware interface)

For Universal model:
- **Any MATLAB version with basic Simulink** (tested on versions from R2018b through R2023a)
- **No additional toolboxes required**
- **No hardware dependencies**
- **No specialized drivers needed**

### Hardware/Software (CAN-based implementation only)
- Vector CAN interface (hardware or virtual)
- Vector CANalyzer (for CAN Explorer visualization)

This dual approach reflects an important engineering principle: always design with deployment constraints in mind. The universal model emerged from feedback from users who couldn't run my original implementation due to licensing or hardware limitations. Rather than requiring specific hardware investments, I developed a solution that preserved the core functionality while removing practical barriers to adoption.

## 🚀 Getting Started

### Option 1: Universal Approach (Recommended for most users)

1. Clone this repository
```
git clone https://github.com/yourusername/F1-Stats-CAN-MATLAB.git
cd F1-Stats-CAN-MATLAB
```

2. In MATLAB, run the Universal model generator script:
```matlab
>> F1_Telemetry_Universal    % Creates and opens a compatible Simulink model
```

3. Run the simulation by clicking the "Run" button in Simulink
   - Data will automatically be logged to your workspace
   - Live visualization will display in the model scopes

### Option 2: CAN-based Implementation (For users with Vector hardware)

1. Clone this repository as above

2. Set up Vector virtual CAN channel (or configure hardware CAN)

3. Run the Python sender script
```
python CAN_Send.py
```

4. In MATLAB, open and run one of the receiver scripts:
```matlab
>> CAN_Receive            % For basic visualization
>> CAN_Receive_Performance % For multi-driver logging
```

5. For driver comparison after data collection:
```matlab
>> CAN_Driver_Analysis    % Interactive driver comparison tool
```

In my testing, I found that the Universal approach was sufficient for most general purposes, while the CAN-based implementation offered a more authentic experience for those specifically interested in automotive communication protocols and hardware integration.

## 📊 Data Processing Workflow

1. **Data Acquisition**: Python extracts telemetry from FastF1
2. **CAN Transmission**: Data is encoded into CAN frames and sent
3. **Real-time Display**: MATLAB receives and visualizes live data
4. **Data Logging**: Telemetry is saved to CSV files by driver
5. **Analysis**: Performance metrics are compared between drivers

## 🔍 Telemetry Signals

The following signals are captured and analyzed:

- **Speed** (km/h): Vehicle speed from 0-255 km/h
- **Throttle** (%): Throttle pedal position (0-100%)
- **Brake** (%): Brake pedal pressure (0-100%)
- **Gear**: Current gear selection (0-15)
- **RPM**: Engine speed in revolutions per minute

## 📈 Use Cases

- Compare driving styles between F1 drivers
- Analyze throttle and brake application techniques
- Study corner entry and exit strategies
- Educational tool for motorsport engineering
- Demonstration of real-time data acquisition systems

## 🔧 Advanced Features

### Universal Model Customization
- Modify sine wave parameters in `F1_Telemetry_Universal.m` to alter signal characteristics
- Extend the model with additional variables (like gear, lateral G-force, etc.)
- Customize scope configurations for different visualization needs
- Add signal processing blocks for data filtering or analysis
- Integrate with external visualization tools via To Workspace blocks

### CAN Implementation Extensions
- Modify `f1.dbc` to add custom signals
- Adjust sampling rates in `CAN_Send.py`
- Create custom MATLAB visualizations
- Extend Simulink model for advanced signal processing
- Implement machine learning for driving pattern recognition

One interesting extension I explored was creating a hybrid approach that allowed the Universal model to record simulated data to CAN format files, enabling compatibility with the analysis tools designed for the hardware-based approach. This allowed for consistent analysis workflows regardless of data source.

## 📞 Contact

For questions or suggestions about this project, please open an issue or contact the repository owner.

---

## 🔑 Technical Insights

Throughout the development of this project, I gained valuable insights about engineering system design that extend well beyond just the technical implementation:

1. **Accessibility vs. Authenticity**: The tension between creating an authentic system (CAN bus) and making it widely accessible (Universal model) demonstrated the importance of considering diverse user constraints early in the design process.

2. **Graceful Degradation**: The universal model showcases how systems can be designed to provide core functionality even without specialized components. This principle of graceful degradation is critical in robust engineering systems.

3. **Cross-Environment Testing**: Validating the system across different MATLAB versions revealed subtle compatibility issues that weren't apparent in the initial development environment, highlighting the importance of comprehensive testing strategies.

4. **User-Focused Documentation**: Creating documentation that serves both technical experts (who want to use the CAN implementation) and novices (who just need a working visualization) required careful organization of information.

5. **Simulation Fidelity**: Designing a simulation that captured the essential characteristics of real telemetry data without exact replication helped identify which aspects of a signal are truly relevant for the intended use case.

These insights continue to guide my approach to engineering system design in my professional work.

**Note**: This project is intended for educational and demonstration purposes. Formula 1 data accessed via FastF1 is subject to Formula 1's terms and conditions.

</div>

<div id="content-fr" style="display: none;">

Une plateforme complète pour capturer, transmettre, visualiser et analyser les données de télémétrie de Formule 1 en utilisant Python, la communication par bus CAN et MATLAB. Ce projet démontre comment :

1. Extraire des données réelles de télémétrie F1 en utilisant l'API FastF1
2. Transmettre des données via bus CAN
3. Visualiser les données de télémétrie en temps réel
4. Enregistrer et analyser les métriques de performance des pilotes

## 🏆 Aperçu du Système

Ce projet crée un pipeline complet de bout en bout pour travailler avec les données de télémétrie F1 :

![Architecture](/images/0.1.png)

- **Extraction de Données** : Utilise l'API Python FastF1 pour accéder aux données historiques des courses F1
- **Transmission CAN** : Envoie des données de télémétrie via un bus CAN virtuel Vector
- **Visualisation en Temps Réel** : Plusieurs scripts MATLAB pour l'affichage de données en direct
- **Analyse de Performance** : Outils pour comparer la télémétrie de différents pilotes
- **Enregistrement de Données** : Enregistre toutes les données reçues pour analyse post-session

### Transmission CAN Python
![Code Python avec Transmission CAN](/images/1.png)

## 🛠️ Composants du Système

### 1. Transmission de Données (`CAN_Send.py`)

Le script Python extrait la télémétrie F1 du Grand Prix du Canada 2023 et la transmet via CAN :
- Récupère la télémétrie du tour le plus rapide pour 20 pilotes F1
- Emballe les données de télémétrie (vitesse, accélérateur, frein, vitesse, RPM) dans des trames CAN
- Transmet les données via une interface CAN virtuelle Vector à des taux configurables
- Comprend la gestion des erreurs et le suivi de la progression

### 2. Format de Message CAN (`f1.dbc`)

Définit la structure du message CAN pour les données de télémétrie :
- ID de message : 291 (0x123 dans le code)
- Définitions des signaux :
  - Vitesse (km/h) : 8 bits non signé (0-255)
  - Accélérateur (%) : 8 bits non signé (0-100)
  - Frein (%) : 8 bits non signé (0-100)
  - Vitesse : 8 bits non signé (0-15)
  - RPM : 16 bits non signé (0-65535)

### 3. Visualisation avec CAN Explorer
![Visualisation CAN Explorer](/images/2.png)

### 4. Réception de Données MATLAB (`CAN_Receive.m`)

Récepteur de télémétrie de base qui :
- Se connecte au canal CAN Vector
- Décode les messages CAN entrants
- Présente les données en temps réel dans un affichage multi-graphiques
- Enregistre toutes les données dans des fichiers CSV horodatés

### 5. Enregistreur de Données de Performance (`CAN_Receive_Performance.m`)

Récepteur amélioré avec :
- Détection et séparation automatique des pilotes
- Enregistrement individuel des données pour chaque pilote
- Visualisation plus propre et plus réactive
- Stockage organisé des données pour analyse

### 6. Visualisation en Temps Réel MATLAB
![Graphiques MATLAB en Temps Réel](/images/3.png)

### 7. Outil d'Analyse des Pilotes (`CAN_Driver_Analysis.m`)

Puissant outil de comparaison qui :
- Charge les journaux de télémétrie de n'importe quels deux pilotes
- Normalise les données par distance pour une comparaison équitable
- Génère des visualisations de performance côte à côte
- Aide à identifier les différences de style de conduite

### 8. Comparaison de Performance des Pilotes
![Analyse Comparative des Pilotes](/images/4.png)

### 9. Intégration Simulink

Comprend des modèles Simulink pour :
- Traitement de données en temps réel (`F1_Telemetry_Sim.slx`)
- Filtrage et analyse avancés des signaux
- Options de visualisation personnalisées
- Capacités d'exportation de signaux
- Modèle universel avec simulation directe des données (`F1_Telemetry_Universal.slx`)

Pour ce projet, j'ai créé deux approches Simulink distinctes :

1. **Modèle basé sur CAN** (`F1_Telemetry_Sim.slx`) : Interface directe avec le matériel Vector pour une communication réelle sur bus CAN. Idéal pour les situations où le matériel est disponible et où un réalisme maximal est requis.

2. **Modèle Universel** (`F1_Telemetry_Universal.slx`) : Simulation entièrement autonome qui ne nécessite aucun matériel ou boîte à outils supplémentaire. Cette solution répond aux défis de compatibilité rencontrés lors du partage du projet avec d'autres utilisateurs ayant des configurations MATLAB différentes.

#### Modèle Simulink Universel
![Modèle Simulink Universel](/images/5.png)

Le modèle `F1_Telemetry_Universal` représente une avancée significative dans mon approche de la visualisation de télémétrie F1. Durant ce projet, j'ai rencontré de nombreux défis de compatibilité avec les versions MATLAB lors de l'implémentation du système de télémétrie basé sur CAN. De nombreux utilisateurs ne pouvaient pas exécuter le modèle original en raison de dépendances matérielles Vector spécifiques et des exigences de boîtes à outils qui variaient selon les versions et licences MATLAB.

Après des semaines de dépannage de ces problèmes de compatibilité, j'ai développé cette solution universelle comme un moyen pratique de fonctionner de manière cohérente dans tous les environnements. L'innovation clé consistait à s'éloigner complètement des dépendances matérielles externes.

Plutôt que de s'appuyer sur des communications de bus CAN externes nécessitant du matériel et des boîtes à outils spécifiques, ce modèle simule les données de télémétrie directement dans Simulink en utilisant des blocs fondamentaux disponibles dans toutes les installations MATLAB. Mon approche offre plusieurs avantages :

- **Compatibilité Universelle** : Fonctionne avec n'importe quelle version de MATLAB (de R2018b à R2023a testée) sans nécessiter de boîtes à outils spécialisées
- **Zéro Dépendance Matérielle** : Élimine le besoin de matériel ou de pilotes Vector CAN auxquels de nombreux utilisateurs n'ont pas accès
- **Performance Constante** : Offre une expérience de visualisation identique sur tous les systèmes, ce qui est idéal pour les environnements collaboratifs
- **Déploiement Simplifié** : Solution en un seul fichier qui fonctionne immédiatement sans procédures de configuration complexes
- **Motifs de Données Réalistes** : Bien que simulées, maintient les caractéristiques essentielles de la télémétrie F1 réelle

L'architecture du modèle est élégamment simple mais efficace. À sa base, j'ai implémenté un système de générateurs d'ondes sinusoïdales avec des paramètres soigneusement calibrés (fréquence, amplitude, biais et phase) pour produire des signaux de télémétrie F1 réalistes pour la vitesse, l'accélérateur, le frein et le RPM. Ces signaux sont mathématiquement conçus pour imiter les modèles réels de données de course tout en maintenant des sorties propres et prévisibles pour une analyse fiable.

Pour améliorer l'utilisation, j'ai ajouté un commutateur manuel qui permet de basculer facilement entre :
1. **Mode de Données Simulées** : Utilisation des générateurs d'ondes sinusoïdales internes pour un fonctionnement complètement autonome
2. **Mode de Données Externes** : Pour les utilisateurs qui ont accès au matériel nécessaire pour intégrer des données CAN réelles

Les composants de visualisation comprennent des oscilloscopes personnalisés codés par couleur (bleu pour la vitesse, vert pour l'accélérateur, rouge pour le frein et magenta pour le RPM) avec une mise à l'échelle appropriée, des affichages numériques montrant les valeurs actuelles, et un enregistrement automatique des variables de l'espace de travail pour l'analyse post-simulation. Toutes les données sont synchronisées en utilisant une base de temps commune pour maintenir des relations appropriées entre les canaux de télémétrie.

Pour ceux intéressés par l'implémentation technique, le modèle :
- Utilise un solveur à pas fixe avec un pas de 0,1s pour une génération de données cohérente
- Emploie des convertisseurs de signaux avec des étiquettes descriptives pour une meilleure lisibilité
- Inclut l'enregistrement automatique des données dans les variables de l'espace de travail pour une analyse ultérieure
- Présente des configurations d'oscilloscope soigneusement ajustées avec des limites d'axe Y appropriées pour chaque canal de télémétrie

Les composants de visualisation incluent des oscilloscopes codés par couleur, des affichages numériques et un enregistrement automatique dans l'espace de travail, tous fonctionnant de manière identique à notre implémentation dépendante du matériel mais sans les maux de tête de compatibilité.

Tout au long de mes tests sur plusieurs versions et environnements MATLAB, j'ai trouvé cette approche remarquablement robuste. Même avec des licences MATLAB limitées ou des versions plus anciennes, le modèle universel fonctionnait de manière constante. Cette adaptabilité s'est avérée particulièrement précieuse lors du travail avec des équipes ayant des configurations techniques variées et un accès différent au matériel.

La philosophie de conception derrière ce modèle reflète mon engagement à créer des solutions d'ingénierie véritablement portables. Bien que l'approche basée sur CAN offre une excellente intégration dans le monde réel, le modèle universel démontre comment l'utilisation intelligente de blocs de construction fondamentaux peut surmonter les limitations pratiques sans sacrifier les fonctionnalités de base. Cet équilibre entre sophistication technique et utilisabilité pratique est quelque chose que je m'efforce d'atteindre dans tous mes projets d'ingénierie.

## 📋 Prérequis

### Python
- Python 3.9+
- `fastf1` : Pour l'accès aux données de télémétrie F1
- `python-can` : Pour la communication par bus CAN

Installation avec :
```bash
pip install fastf1 python-can
```

### MATLAB
Pour l'implémentation basée sur CAN :
- MATLAB R2021a ou plus récent recommandé pour une fonctionnalité complète
- Vehicle Network Toolbox (requis pour la communication CAN)
- Simulink (requis pour les modèles de visualisation)
- Pilotes CAN Vector (pour l'interface matérielle)

Pour le modèle Universel :
- **N'importe quelle version de MATLAB avec Simulink de base** (testé sur les versions de R2018b à R2023a)
- **Aucune boîte à outils supplémentaire requise**
- **Aucune dépendance matérielle**
- **Aucun pilote spécialisé nécessaire**

### Matériel/Logiciel (implémentation basée sur CAN uniquement)
- Interface CAN Vector (matérielle ou virtuelle)
- Vector CANalyzer (pour la visualisation CAN Explorer)

Cette double approche reflète un principe d'ingénierie important : toujours concevoir en tenant compte des contraintes de déploiement. Le modèle universel est né des retours d'utilisateurs qui ne pouvaient pas exécuter mon implémentation originale en raison de limitations de licence ou de matériel. Plutôt que d'exiger des investissements matériels spécifiques, j'ai développé une solution qui préservait les fonctionnalités de base tout en supprimant les barrières pratiques à l'adoption.

## 🚀 Démarrage

### Option 1 : Approche Universelle (Recommandée pour la plupart des utilisateurs)

1. Clonez ce dépôt
```
git clone https://github.com/yourusername/F1-Stats-CAN-MATLAB.git
cd F1-Stats-CAN-MATLAB
```

2. Dans MATLAB, exécutez le script générateur de modèle Universel :
```matlab
>> F1_Telemetry_Universal    % Crée et ouvre un modèle Simulink compatible
```

3. Exécutez la simulation en cliquant sur le bouton "Run" dans Simulink
   - Les données seront automatiquement enregistrées dans votre espace de travail
   - La visualisation en direct s'affichera dans les oscilloscopes du modèle

### Option 2 : Implémentation basée sur CAN (Pour les utilisateurs disposant de matériel Vector)

1. Clonez ce dépôt comme ci-dessus

2. Configurez un canal CAN virtuel Vector (ou configurez le matériel CAN)

3. Exécutez le script d'envoi Python
```
python CAN_Send.py
```

4. Dans MATLAB, ouvrez et exécutez l'un des scripts de réception :
```matlab
>> CAN_Receive            % Pour la visualisation de base
>> CAN_Receive_Performance % Pour l'enregistrement multi-pilotes
```

5. Pour la comparaison des pilotes après la collecte de données :
```matlab
>> CAN_Driver_Analysis    % Outil interactif de comparaison des pilotes
```

Dans mes tests, j'ai constaté que l'approche Universelle était suffisante pour la plupart des usages généraux, tandis que l'implémentation basée sur CAN offrait une expérience plus authentique pour ceux spécifiquement intéressés par les protocoles de communication automobile et l'intégration matérielle.

## 📊 Flux de Traitement des Données

1. **Acquisition de Données** : Python extrait la télémétrie de FastF1
2. **Transmission CAN** : Les données sont encodées dans des trames CAN et envoyées
3. **Affichage en Temps Réel** : MATLAB reçoit et visualise les données en direct
4. **Enregistrement de Données** : La télémétrie est enregistrée dans des fichiers CSV par pilote
5. **Analyse** : Les métriques de performance sont comparées entre les pilotes

## 🔍 Signaux de Télémétrie

Les signaux suivants sont capturés et analysés :

- **Vitesse** (km/h) : Vitesse du véhicule de 0 à 255 km/h
- **Accélérateur** (%) : Position de la pédale d'accélérateur (0-100%)
- **Frein** (%) : Pression de la pédale de frein (0-100%)
- **Vitesse** : Sélection de vitesse actuelle (0-15)
- **RPM** : Régime moteur en tours par minute

## 📈 Cas d'Utilisation

- Comparer les styles de conduite entre les pilotes F1
- Analyser les techniques d'application de l'accélérateur et du frein
- Étudier les stratégies d'entrée et de sortie de virage
- Outil éducatif pour l'ingénierie du sport automobile
- Démonstration des systèmes d'acquisition de données en temps réel

## 🔧 Fonctionnalités Avancées

### Personnalisation du Modèle Universel
- Modifier les paramètres d'onde sinusoïdale dans `F1_Telemetry_Universal.m` pour modifier les caractéristiques du signal
- Étendre le modèle avec des variables supplémentaires (comme la vitesse, la force G latérale, etc.)
- Personnaliser les configurations d'oscilloscope pour différents besoins de visualisation
- Ajouter des blocs de traitement de signal pour le filtrage ou l'analyse des données
- Intégrer avec des outils de visualisation externes via des blocs To Workspace

### Extensions d'Implémentation CAN
- Modifier `f1.dbc` pour ajouter des signaux personnalisés
- Ajuster les taux d'échantillonnage dans `CAN_Send.py`
- Créer des visualisations MATLAB personnalisées
- Étendre le modèle Simulink pour un traitement avancé des signaux
- Implémenter l'apprentissage automatique pour la reconnaissance des modèles de conduite

Une extension intéressante que j'ai explorée était la création d'une approche hybride qui permettait au modèle Universel d'enregistrer des données simulées au format CAN, permettant la compatibilité avec les outils d'analyse conçus pour l'approche basée sur le matériel. Cela a permis des flux de travail d'analyse cohérents quelle que soit la source des données.

## 📞 Contact

Pour des questions ou des suggestions concernant ce projet, veuillez ouvrir une issue ou contacter le propriétaire du dépôt.

---

## 🔑 Aperçus Techniques

Tout au long du développement de ce projet, j'ai acquis de précieux insights sur la conception de systèmes d'ingénierie qui s'étendent bien au-delà de la simple implémentation technique :

1. **Accessibilité vs. Authenticité** : La tension entre la création d'un système authentique (bus CAN) et sa large accessibilité (modèle Universel) a démontré l'importance de considérer les contraintes diverses des utilisateurs dès le début du processus de conception.

2. **Dégradation Gracieuse** : Le modèle universel montre comment les systèmes peuvent être conçus pour fournir des fonctionnalités de base même sans composants spécialisés. Ce principe de dégradation gracieuse est essentiel dans les systèmes d'ingénierie robustes.

3. **Tests Cross-Environment** : La validation du système à travers différentes versions MATLAB a révélé des problèmes de compatibilité subtils qui n'étaient pas apparents dans l'environnement de développement initial, soulignant l'importance des stratégies de test complètes.

4. **Documentation Axée sur l'Utilisateur** : La création d'une documentation qui sert à la fois les experts techniques (qui veulent utiliser l'implémentation CAN) et les novices (qui ont juste besoin d'une visualisation fonctionnelle) a nécessité une organisation soigneuse de l'information.

5. **Fidélité de Simulation** : La conception d'une simulation qui capturait les caractéristiques essentielles des données de télémétrie réelles sans réplication exacte a aidé à identifier quels aspects d'un signal sont vraiment pertinents pour le cas d'utilisation prévu.

Ces aperçus continuent de guider mon approche de la conception de systèmes d'ingénierie dans mon travail professionnel.

**Remarque** : Ce projet est destiné à des fins éducatives et de démonstration. Les données de Formule 1 accessibles via FastF1 sont soumises aux conditions générales de la Formule 1.

</div>

<script>
function toggleLanguage() {
  var buttonText = document.getElementById("lang-toggle");
  var englishContent = document.getElementById("content-en");
  var frenchContent = document.getElementById("content-fr");
  
  if (englishContent.style.display === "none") {
    englishContent.style.display = "block";
    frenchContent.style.display = "none";
    buttonText.innerHTML = "Switch to French / Passer au français";
  } else {
    englishContent.style.display = "none";
    frenchContent.style.display = "block";
    buttonText.innerHTML = "Switch to English / Passer à l'anglais";
  }
}
</script>
