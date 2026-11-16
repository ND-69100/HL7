# HL7Transfert — Interface HL7 (Delphi XE5, VCL)

Application VCL Delphi XE5 permettant de traiter les fichiers HL7 déposés dans un
répertoire et d'en extraire les données.

## Principe

Les fichiers HL7 (extension `*.hl7`) sont déposés dans un répertoire. L'application :

1. liste les fichiers `*.hl7` présents dans le dossier choisi (bouton **Parcourir...**),
2. peut surveiller le dossier en continu (case **Surveiller le dossier**, rafraîchissement
   toutes les 2 secondes via un `TTimer`) pour détecter les nouveaux dépôts,
3. parse le fichier sélectionné (clic dans la liste) : segments séparés par CR (les
   délimiteurs de message HL7 `0x0B` / `0x1C` sont aussi acceptés), champs séparés par le
   séparateur de champ du MSH (`|` par défaut), composantes par `^`, sous-composantes par `&`,
   répétitions par `~` — les délimiteurs sont lus dans le segment MSH,
4. affiche la structure du message (segment → champ → composante) dans un arbre,
5. extrait les données clés dans l'onglet **Données extraites** : type de message (MSH-9),
   date (MSH-7), expéditeur/destinataire (MSH-3 à MSH-6), patient (PID-3, PID-5, PID-7,
   PID-8), visite (PV1-2, PV1-19), examen (OBR-4, OBR-7) et observations (OBX-3, OBX-5,
   OBX-6, OBX-7, OBX-11),
6. exporte les données extraites en CSV (séparateur `;`, UTF-8) : un fichier sélectionné
   (**Exporter la sélection...**) ou tous les fichiers du dossier (**Exporter tous les
   fichiers...**), une ligne par segment OBX.

## Fichiers du projet

| Fichier | Rôle |
|---|---|
| `HL7Transfert.dpr` / `HL7Transfert.dproj` | Projet Delphi XE5 (Win32, VCL) |
| `uMain.pas` / `uMain.dfm` | Fiche principale (dossier, liste des fichiers, arbre, extraction, export CSV) |
| `uHL7.pas` | Parseur de messages HL7 (`THL7Message`, `THL7Segment`) |
| `uHL7Extract.pas` | Extraction des données (résumé texte + lignes CSV) |
| `exemples/` | Exemples de fichiers HL7 (`ADT^A01`, `ORU^R01`) à déposer dans le dossier de test |

## Utilisation

1. Ouvrir `HL7Transfert.dproj` dans Delphi XE5 et compiler (Win32).
2. Au démarrage, le dossier par défaut est le sous-dossier `HL7` à côté de l'exécutable
   s'il existe, sinon le dossier de l'exécutable. Choisir le répertoire de dépôt avec
   **Parcourir...**.
3. Cocher **Surveiller le dossier** pour rafraîchir automatiquement la liste quand de
   nouveaux fichiers HL7 sont déposés.
4. Cliquer sur un fichier pour afficher sa structure et ses données extraites.
5. **Exporter...** pour produire un CSV des données extraites.

## Notes

- L'encodage du fichier est détecté (BOM UTF-8 / UTF-16) ; sinon l'encodage ANSI par
  défaut est utilisé.
- Les sources `.pas`/`.dfm` sont volontairement en ASCII pour rester lisibles quelle que
  soit la page de code de l'IDE.
