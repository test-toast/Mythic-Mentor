-- Table of French strings
L_frFR = {
    -----------------------------------------------
    -- UI Labels
    -----------------------------------------------
    ["DUNGEONS"] = "Donjons",
    ["GENERAL"] = "Général",
    ["BACK"] = "Retour",
    ["POST_TO_CHAT"] = "Envoyer au chat",
    ["COPY_TEXT"] = "Copier le texte",
    ["COMING_SOON"] = "Bientôt disponible",
    ["HIDE_DETAILS"] = "Masquer les détails",
    ["SHOW_DETAILS"] = "Afficher les détails",
    ["THIS_WEEK_AFFIXES"] = "Affixes de la semaine",
    ["AFFIXES"] = "Affixes",
    ["AFFIXES_LOADING"] = "Affixes pas encore disponibles. Réessayez bientôt.",

    -- Dungeon Check Window
    ["DCW_TITLE"] = "Check",
    ["DCW_DURABILITY"] = "Durabilité",
    ["DCW_FLASK"] = "Flacon",
    ["DCW_FOOD"] = "Nourriture",
    ["DCW_ACTIVE"] = "Actif",
    ["DCW_NOT_APPLIED"] = "Non appliqué",
    ["DCW_NONE_IN_BAGS"] = "Aucun dans les sacs",
    ["DCW_READY_CHECK"] = "Ready Check",
    ["DCW_COUNTDOWN"] = "Compte à rebours",
    ["DCW_CATE"] = "Vérification Donjon",
    ["DCW_SETTINGS_BEHAVIOR"] = "Affichage / Vérifications",
    ["DCW_SETTINGS_APPEARANCE"] = "Apparence",
    ["DCW_SHOW_SPEC_TITLE"] = "Afficher la Spé",
    ["DCW_SHOW_SPEC_TOOLTIP"] = "Afficher l'icône, le nom et le rôle de la spécialisation.",
    ["DCW_SHOW_DUR_TITLE"] = "Afficher la Durabilité",
    ["DCW_SHOW_DUR_TOOLTIP"] = "Afficher le pourcentage de durabilité global de l'équipement.",
    ["DCW_SHOW_FLASK_TITLE"] = "Afficher Flacon",
    ["DCW_SHOW_FLASK_TOOLTIP"] = "Afficher l'état du buff flacon/fiole et le nombre en sacs.",
    ["DCW_SHOW_FOOD_TITLE"] = "Afficher Nourriture",
    ["DCW_SHOW_FOOD_TOOLTIP"] = "Afficher l'état du buff Well Fed et le nombre en sacs.",
    ["DCW_SHOW_BTNS_TITLE"] = "Afficher Boutons",
    ["DCW_SHOW_BTNS_TOOLTIP"] = "Afficher les boutons Ready Check et Compte à rebours (chef de groupe seulement).",
    ["DCW_NO_BORDER_TITLE"] = "Masquer la bordure",
    ["DCW_NO_BORDER_TOOLTIP"] = "Supprimer la bordure de la fenêtre de vérification de donjon.",
    ["DCW_TRANSPARENT_TITLE"] = "Transparence du fond",
    ["DCW_TRANSPARENT_TOOLTIP"] = "Ajustez la transparence du fond (0% = totalement transparent, 100% = opaque).",
    ["DCW_ENABLED_TITLE"] = "Activer Dungeon Check",
    ["DCW_ENABLED_TOOLTIP"] = "Activer ou désactiver le Dungeon Check. Lorsqu'il est actif, s'ouvre automatiquement en entrant dans un donjon Mythic+. Affiche la spécialisation, le rôle, la durabilité de l'équipement, ainsi que le statut du flacon et de la nourriture. Le chef de groupe peut lancer une vérification de disponibilité ou un compte à rebours depuis cette fenêtre. Se ferme automatiquement lorsque le minuteur du donjon démarre. Lorsqu'il est désactivé, la fenêtre n'apparaît jamais.",
    ["DCW_OPEN_BTN"] = "Ouvrir la fenêtre",
    ["DCW_OPEN_BTN_TOOLTIP"] = "Ouvrir la fenêtre de vérification de donjon.",
    ["SETTINGS_HOVER_HINT"] = "Survolez un paramètre pour voir les infos.",
    ["ROLE_TANK"] = "Tank",
    ["ROLE_HEALER"] = "Healer",
    ["ROLE_DPS"] = "DPS",


    -----------------------------------------------
    -- settings
    -----------------------------------------------
    ["SETTINGS"] = "Paramètres",

    -- category names
    ["GENERAL_CATE"] = "Général",
    ["AUTO_INVITE_CATE"] = "Auto-Invitation",

    -- text
    ["/RELOAD_TEXT"] = "Tactiques mises à jour. Utilisez /reload pour la traduction de l'interface.",

    -- Section headers
    ["SETTINGS_DISPLAY_SECTION"] = "Affichage",
    ["SETTINGS_BEHAVIOR_SECTION"] = "Comportement",
    ["SETTINGS_MINIMAP_SECTION"] = "Minimap",
    ["SETTINGS_APPEARANCE_SECTION"] = "Apparence",

    -- Setting Main
    ["SELECT_LANGUAGE_TITLE"] = "Sélectionner la langue",
    ["SCALE_SLIDER_TITLE"] = "Échelle de l'addon",
    ["ANIMATIONS_COMBT_TITLE"] = "Autoriser les animations en combat",
    ["CLOSE_WINDOW_TITLE"] = "Fermer la fenêtre après envoi",
    ["ESC_CLOSE_TITLE"] = "Autoriser la fermeture avec ESC",
    ["AUTO_OPEN_NOTES_TITLE"] = "Ouvrir automatiquement les notes de boss",
    ["MINIMAP_BTN_TITLE"] = "Masquer le bouton de la minicarte",

    ["AUTO_INVITE_TITLE"]      = "Activer l'auto-invitation",
    ["TRIGGER_FRIENDLY_TITLE"] = "Guilde & Amis",
    ["TRIGGER_OTHER_TITLE"]    = "Autres",
    ["TRIGGER_INPUT_HINT"]     = "Tapez et appuyez sur Entrée pour ajouter...",
    ["TRIGGER_NONE"]           = "(aucun)",

    -- ToolTip settings
    ["LANGUAGE_TOOLTIP_1"] = "Choisissez la langue utilisée dans Mythic Mentor.",
    ["LANGUAGE_TOOLTIP_2"] = "Cliquez pour ouvrir la liste des langues disponibles.",
    ["SCALE_TOOLTIP"] = "Modifie l'échelle de l'addon. Faites glisser pour changer.",
    ["CURRENT_SCALE_TOOLTIP"] = "Actuel : ",
    ["ANIMATIONS_TOOLTIP"] = "Jouer les animations en combat.",
    ["CLOSE_WINDOW_TOOLTIP"] = "Fermer la fenêtre après avoir cliqué sur 'Envoyer au chat'.",
    ["ESC_CLOSE_TOOLTIP"] = "Fermer la fenêtre avec ESC.",
    ["AUTO_OPEN_NOTES_TOOLTIP"] = "Ouvrir automatiquement le panneau des notes de boss\nlors de la sélection d'un boss (si des notes existent).",
    ["MINIMAP_BTN_TOOLTIP"] = "Masquer ou afficher le bouton de la minicarte pour Mythic Mentor.",

    ["AUTO_INVITE_TOOLTIP"] = "Activer ou désactiver l'auto-invitation. Lorsqu'il est actif, les joueurs qui chuchotent un mot déclencheur configuré sont automatiquement invités dans votre groupe. Des listes de déclencheurs séparées sont disponibles pour la guilde/les amis et pour tous les autres.",

    -- Mini Window settings
    ["MINI_WINDOW_CATE"] = "Mini-fenêtre",
    ["MINI_WINDOW_TRANSPARENT_TITLE"] = "Transparence du fond",
    ["MINI_WINDOW_TRANSPARENT_TOOLTIP"] = "Ajustez la transparence du fond (0% = totalement transparent, 100% = opaque).",
    ["MINI_WINDOW_NO_BORDER_TITLE"] = "Masquer la bordure",
    ["MINI_WINDOW_NO_BORDER_TOOLTIP"] = "Supprime la bordure de la mini-fenêtre.",
    ["MINI_WINDOW_HIDE_SEP_TITLE"] = "Masquer le séparateur",
    ["MINI_WINDOW_HIDE_SEP_TOOLTIP"] = "Masque la fine ligne de séparation sous l'en-tête de la mini-fenêtre.",
    ["MINI_WINDOW_ICONS_ONLY_TITLE"] = "Icônes seulement (masquer le chrome des boutons)",
    ["MINI_WINDOW_ICONS_ONLY_TOOLTIP"] = "Supprime le fond et la bordure des boutons de fenêtre, n'affiche que les icônes.",
    ["MINI_WINDOW_ENABLED_TITLE"] = "Activer la Mini Fenêtre",
    ["MINI_WINDOW_ENABLED_TOOLTIP"] = "Activer ou désactiver la Mini Fenêtre. Lorsqu'elle est active, s'ouvre automatiquement en entrant dans un donjon Mythic+, affichant les tactiques pour le combat de boss en cours et passant automatiquement au boss suivant lorsque le boss actuel est vaincu.",
    ["MINI_WINDOW_AUTO_EXPAND_TITLE"] = "Auto-agrandir lors d'un pull de boss",
    ["MINI_WINDOW_AUTO_EXPAND_TOOLTIP"] = "Agrandit automatiquement la Mini Fenêtre lorsqu'un combat de boss commence, et la réduit à nouveau lorsque le boss est mort.",
    ["MINI_WINDOW_OPEN_BTN"] = "Ouvrir la Mini Fenêtre",
    ["MINI_WINDOW_OPEN_BTN_TOOLTIP"] = "Ouvre la Mini Fenêtre (identique à /mmw).",

    -- Catégorie Key Tracker
    ["KEY_TRACKER_CATE"] = "Key Tracker",
    ["KEY_TRACKER_SECTION"] = "Affichage",
    ["KEY_TRACKER_STARTPAGE_TITLE"] = "Afficher les clés sur la page de démarrage",
    ["KEY_TRACKER_STARTPAGE_TOOLTIP"] = "Affiche le widget de suivi des pierres de clé en bas de la page de démarrage.",
    ["KEY_TRACKER_GROUPFINDER_TITLE"] = "Afficher les clés dans le Groupe Finder",
    ["KEY_TRACKER_GROUPFINDER_TOOLTIP"] = "Affiche le panneau de suivi des clés attaché à la fenêtre du Groupe Finder.",

    -- Apparence du panneau Groupe Finder
    ["KEY_TRACKER_STARTPAGE_CARD"] = "Suivi Page de démarrage",
    ["KEY_TRACKER_GF_APPEARANCE"] = "Panneau Groupe Finder",
    ["KEY_TRACKER_GF_TRANSPARENT_TITLE"] = "Transparence du fond",
    ["KEY_TRACKER_GF_TRANSPARENT_TOOLTIP"] = "Ajustez la transparence du fond (0% = totalement transparent, 100% = opaque).",
    ["KEY_TRACKER_GF_NO_BORDER_TITLE"] = "Masquer la bordure",
    ["KEY_TRACKER_GF_NO_BORDER_TOOLTIP"] = "Supprime la bordure du panneau Groupe Finder.",
    ["KEY_TRACKER_GF_HIDE_TITLE_TITLE"] = "Masquer l'en-tête 'Keys'",
    ["KEY_TRACKER_GF_HIDE_TITLE_TOOLTIP"] = "Masque l'étiquette 'Keys' en haut du panneau Groupe Finder.",
    ["KEY_TRACKER_ENABLED_TITLE"] = "Activer le Suivi de Clé",
    ["KEY_TRACKER_ENABLED_TOOLTIP"] = "Activer ou désactiver le Suivi de Clé. Lorsqu'il est actif, il suit les pierres de clé pour vous et votre groupe, les affichant sur la page de démarrage et dans le panneau Groupe Finder. Lorsqu'il est désactivé, aucune donnée de clé n'est collectée et les panneaux de suivi sont masqués.",
    ["NO_KEY"] = "Pas de clé",

    -- Paramètres de téléportation
    ["TELEPORT_CARD"] = "Téléport",
    ["TELEPORT_KEY_CARDS_TITLE"] = "Key Card Teleport",
    ["TELEPORT_KEY_CARDS_TOOLTIP"] = "Cliquez sur l'image du donjon sur les cartes de pierre de clé (page de démarrage) pour vous téléporter directement à ce donjon.",
    ["TELEPORT_KEY_LIST_TITLE"] = "Key List Teleport",
    ["TELEPORT_KEY_LIST_TOOLTIP"] = "Cliquez sur l'icône du donjon dans les rangées de pierres de clé (panneau Groupe Finder) pour vous téléporter directement à ce donjon.",
    ["TELEPORT_MYTHIC_TAB_TITLE"] = "Mythic+ Tab Teleport",
    ["TELEPORT_MYTHIC_TAB_TOOLTIP"] = "Ajoute un bouton de téléportation cliquable sur chaque icône de donjon dans l'onglet Mythic+ (Défis) du Groupe Finder.",
    ["TELEPORT_IN_COMBAT"] = "Impossible de se téléporter en combat.",
    ["TELEPORT_READY"] = "Prêt",
    ["TELEPORT_COOLDOWN"] = "Prêt dans : ",
    ["TELEPORT_NOT_LEARNED"] = "Sort non appris.",

    -----------------------------------------------
    -- Start Side
    -----------------------------------------------

    -- Text
    ["SELECT_DUNGEON_HINT"] = "Sélectionnez un donjon dans le panneau gauche pour voir les boss et les tactiques.",
    ["START_PAGE_HIDE_GUIDE_TITLE"] = "Masquer le guide de la page d'accueil",
    ["START_PAGE_HIDE_GUIDE_TOOLTIP"] = "Masque le texte d'aide sur la page d'accueil et centre le logo.",

    -----------------------------------------------
    -- Notes
    -----------------------------------------------

    -- Boss Notes
    ["BOSS_NOTES"] = "Notes de boss",
    ["BOSS_CLOSE_NOTE"] = "Fermer la note",
    ["ADD_NOTE_TIP"] = "Écrivez une note et appuyez sur Entrée :",

    -- General Notes
    ["GENERAL_NOTES"] = "Notes générales",
    ["ADD_CATEGORY"] = "Nouvelle catégorie",
    ["DEFAULT_CATEGORY"] = "Tous",
    ["CONFIRM_DELETE_NOTE"] = "Êtes-vous sûr de vouloir supprimer cette note ?",
    ["CONFIRM_DELETE_CATEGORY"] = "Êtes-vous sûr de vouloir supprimer cette catégorie et toutes ses notes ?",
    ["CONFIRM_DELETE_NOTE_TITLE"] = "Supprimer la note",
    ["CONFIRM_DELETE_CATEGORY_TITLE"] = "Supprimer la catégorie",


    -----------------------------------------------
    -- Info panel
    -----------------------------------------------

    ["INFO"] = "Informations",


    -----------------------------------------------
    -- Socials
    -----------------------------------------------
    ["DISCORD_TOOLTIP"] = "Cliquez pour obtenir le lien Discord.",
    ["JOIN_DISCORD"] = "Rejoignez notre Discord !",

    ["GITHUB_TOOLTIP"] = "Cliquez pour obtenir le lien GitHub.",
    ["VISIT_GITHUB"] = "Visitez notre GitHub !",

    ["BUG_TOOLTIP"] = "Cliquez pour signaler un bug.",
    ["REPORT_BUG"] = "Signaler un bug !",
    ["BUG_GUIDE"] = "Vous avez trouvé un bug ? Signalez-le via Discord ou GitHub Issues.",


    ["COPY_LINK"] = "Ctrl+C pour copier le lien",
    ["COPY_HINT_TEXT"] = "— ferme la fenêtre",
    ["UNKNOWN_BOSS"] = "Boss inconnu",
    ["TITAN_LEFT_CLICK"] = "Clic gauche : Ouvrir Mythic Mentor",
    ["TITAN_RIGHT_CLICK"] = "Clic droit : Ouvrir le menu",

    -----------------------------------------------
    -- Update banner
    -----------------------------------------------
    ["UPDATE_AVAILABLE_BANNER"] = "Nouvelle mise à jour disponible – La vôtre : %s  Nouvelle : %s  (cliquez pour ouvrir)",

    -----------------------------------------------
    -- Edit Tactics
    -----------------------------------------------
    ["TACTIC_PLACEHOLDER"] = "Écrivez la tactique ici...",
    ["DELETE"] = "Supprimer",
    ["SAVE"] = "Sauvegarder",
    ["RESET"] = "Réinitialiser",
    ["CANCEL"] = "Annuler",
    ["EDIT_TACTICS_TOOLTIP"] = "Modifier les tactiques",
    ["EDIT_TACTICS_BETA_TITLE"] = "Modifier les tactiques - Bêta",
    ["EDIT_TACTICS_BETA_MSG"] = "La modification des tactiques de boss est une nouvelle fonctionnalité.\n\nDes bugs peuvent survenir. Si vous en trouvez, veuillez les signaler sur notre Discord ou GitHub.\n\nVoulez-vous continuer ?",
    ["FILTER_PHASE_TOOLTIP"] = "Filtrer la phase",
    ["DELETE_PHASE_TITLE"] = "Supprimer la phase",
    ["DELETE_PHASE_MSG"] = "Êtes-vous sûr de vouloir supprimer la phase '%s' et toutes ses tactiques ?\n\nCette action est irréversible.",
    ["ADD_TACTIC_BTN"] = "+ Ajouter une tactique",
    ["RESET_TACTICS_TITLE"] = "Réinitialiser les tactiques",
    ["RESET_TACTICS_MSG"] = "Êtes-vous sûr de vouloir réinitialiser toutes les tactiques pour ce boss ?\n\nCette action est irréversible.",
    ["UNSAVED_CHANGES_TITLE"] = "Modifications non sauvegardées",
    ["UNSAVED_CHANGES_MSG"] = "Vous avez des modifications non sauvegardées.\n\nÊtes-vous sûr de vouloir annuler sans sauvegarder ?",

    -----------------------------------------------
    -- Update popup
    -----------------------------------------------
    ["UPDATE_POPUP_TEXT"] = "Une nouvelle version de Mythic Mentor est disponible !\n\nLa vôtre : %s\nNouvelle : %s\n\nOuvrir GitHub pour mettre à jour ?",
    ["UPDATE_POPUP_BTN_GITHUB"] = "GitHub",

    -----------------------------------------------
    -- Messages d'erreur / statut
    -----------------------------------------------
    ["CMD_UI_NOT_READY"]      = "L'interface n'est pas encore prête. Veuillez réessayer dans un instant.",
    ["CMD_UI_NOT_LOADED"]     = "BossUI n'est pas chargé.",
    ["CMD_DCW_NOT_LOADED"]    = "DungeonCheckWindow n'est pas chargé.",
    ["CHAT_SEND_FAILED"]      = "Échec de l'envoi du message : ",
    ["CHAT_NOT_IN_GROUP"]     = "Pas dans un groupe – les messages ne seront visibles que par vous.",
    ["INVITE_FN_UNAVAILABLE"] = "Fonction d'invitation non disponible.",
    ["INVITE_NOT_LEADER"]     = "Vous n'êtes pas chef/assistant de groupe.",
    ["INVITE_FAILED_FOR"]     = "Échec de l'invitation pour : ",
    ["ESC_REGISTER_FAILED"]   = "Impossible d'enregistrer le cadre pour la fermeture ESC (nom manquant).",
}

return L_frFR
