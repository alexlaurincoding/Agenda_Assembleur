;******************************************************************************* 
;*                          Alexandre Laurin                                   *
;*                              11/25/2021                                     *
;*                                TP3                                          *
;*                                                                             *
;* Ce programme gere un agenda Hebdomadaire des evenements.                    *                 
;* Chaque evenement est defini par un ensemble d'informations:                 *
;*       Jour de la semaine ( un entier de 1 a 7, 1 = lundi et 7 = dimanche)   * 
;*       Heure de debut en minutes ( un entier positif de 0 a 1440 )           *
;*       Duree en minutes ( un entier positif de 0 a 1440 )                    *
;* 1440 representant les minutes d'une journee (24 heures * 60 minutes = 1440).* 
;*                                                                             *                                                  
;*******************************************************************************

         LDA     0,i
         LDX     0,i

;Main() Porte d'entree du programme. Appel des fonctions Agenda() et AffAgd()
main:    CALL    Agenda
         LDA     head,d
         CALL    AffAgd
         
         STOP

;Fonction Agenda() Cree un agenda hebdomadaire et letourne la liste des
; evenement de la semaine.
;OUT : adresse de head
Agenda:  STRO    msgMenu,d
         STRO    affChoix,d
         DECI    choix,d     ;choix de l'utilisateur(1-saisir ou 2-quitter)
         LDA     choix,d     ;A = choix
         CPA     chQuitte,i  ;Validation du choix
         BREQ    quitter     ;Si A == 2 quitter
         CPA     chSaisir,i
         BREQ    goCreer     ;Si A == 1, cree un nouvel evenement
         BR      Agenda      ;Sinon on redemande
goCreer: CALL    Creer       ;Appel de la methode Cree()
         CPA     0,i         ;Si A = 0, une erreur est survenue, recommencer
         BREQ    Agenda

;Utilisation du stack pour le passage de parametre a Inserer(event, head)
;IN: event, head
;OUT: boolean ( 0 ou 1 ) si l'event est ajouter
valHead:.EQUATE 0            ;#2d
valEvent:.EQUATE 2           ;#2d
valRet:  .EQUATE 4           ;#2d
         SUBSP   6,i         ;Allocation de 6 case ;#valRet  #valEvent #valHead
         STX     valEvent, s ;Addresse de l'event a ajouter        
         STA     valHead, s  ;Addresse du head de la liste
         LDX     0,i
         STX     valRet,s
         CALL    Inserer     ;Appel de la fonction Inserer
         LDX     valRet,s
         CPX     1,i
         BRNE    false
         LDA     valHead,s   ;Obtention du head a partir du stack
         STA     head,d      ; Sauvegarde de head dans la variable globale
false:   ADDSP   6,i         ;Desalocation du stack ;#valHead  #valEvent #valRet
         BR      Agenda
quitter: RET0 
chSaisir:.EQUATE 1
chQuitte:.EQUATE 2
choix:   .BLOCK  2
msgMenu: .ASCII  "******************\n"
msgMenu2:.ASCII  "*   [1]-Saisir   *\n"
msgMenu3:.ASCII  "*   [2]-Quitter  *\n"
msgMenu4:.ASCII  "******************\n\x00"
affChoix:.ASCII  "Votre choix : \x00"

;Fonction Inserer(Event* ev, Event& head)
;Cette fonction prend une addresse de maillon et l'insere dans la liste en
; ordre cronologique, Si un conflit d'horaire est detecter, l'insertion 
;est annule et la valeur 0 est retourne par la pile.
                 ;Allocation de 12 case dans le stack pour variable locales
Inserer: SUBSP   12,i        ;#elemPrec #finLi #debutLi #newFin #newDebut #element 
         LDA     headLoc, s  ;Adresse de head
         STA     element,s   ;element = addresse de head
         LDA     newEvLoc,s  ;Adresse de l'event
         CPA     headLoc,s   ;cp avec head
         BREQ    succes    ;Si l'evenement est le head 
;Validation
         CALL    CDebFin     ;Trouver debut et fin du nouvel evenement en minutes
         STA     newDebut,s  ;Sauvegarde des valeurs debut et fin
         STX     newFin,s
parcour: LDA     element,s   ;element de la liste a comparer
         CALL    CDebFin     ;Trouver le debut et fin de l'element a comparer
         STA     debutLi,s   ;Sauvegarde dans le stack
         STX     finLi,s
         LDA     newDebut,s  ;Comparaison du debut des deux elements
         CPA     debutLi,s
         BRLT    avant       ;Si A < debutLi l'evenement a inserer est avant
         BREQ    invalide    ;Si a == debutLi, invalide
         BRGT    apres       ;Si A > debutLi l'evenement a inserer est apres

;Insertion de l'evenement avant l'element de la liste en cours de comparaison
avant:   LDA     newFin,s    ;Valider la fin du nouvel evenement n'empiete pas
         CPA     debutLi,s   ; sur le debut de l'evenement suivant
         BRGT    invalide    ;Si oui, invalide
         LDX     mPrec,i
         LDA     element,sxf ;Ajoute/modifie la valeur de elementPrecedant de
         CPA     0,i         ;verifie l'element suivant etais le head
         BREQ    newHead     ;Si oui, on change le head pour le nouvel evenement
                             ;Sinon l'ajout se fait entre deux element.

;Ajout entre deux elements
         LDA     element,s   ;A = element suivant
         LDX     mSuivant,i
         STA     newEvLoc,sxf ;Case suivant du nouvel element = A 
         LDX     mPrec,i     
         LDA     element,sxf ;A = element precedant
         STA     elemPrec,s  ;Sauvegarde
         STA     newEvLoc,sxf ;Case precedant du nouvel element = A
         LDA     newEvLoc,s  ;A = Adresse du nouvel element
         STA     element,sxf ;Case precedant de l'element suivant  = A
         LDX     mSuivant,i
         STA     elemPrec,sxf ;Case suivant de l'element precedant = A
         BR      succes

newHead: LDA     newEvLoc,s ;A = Adresse du nouvel element
         STA     headLoc,s  ; valeur head de la pile = A
         LDX     mPrec,i     
         STA     element,sxf ;Case precedant de l'element suivant  = A
         LDX     mSuivant,i
         LDA     element,s   ;A = addresse de l'element suivant
         STA     newEvLoc,sxf ;Case suivant du nouvel element = A
         BR      succes

apres:   CPA     finLi,s     ;Si debut nouvel event < fin elem precedent
         BRLT    invalide    ;Invalide
         LDX     mSuivant,i  ;
         LDA     element,sxf ;A = element suivant du precedant
         CPA     0,i         ;Si A == 0 -> fin de la liste on ajoute
         BRNE    next        ;Sinon on compare au prochain
         LDA     newEvLoc,s  ;A = adresse du nouvel evenement
         STA     element,sxf ;Case suiv de l'element precedant = A
         LDA     element,s   ;A = addresse de l'element precedant
         LDX     mPrec,i
         STA     newEvLoc,sxf ;Case precedant du nouvel element = A
         BR      succes

next:    STA     element,s   ;Trouve le prochain element a comparer
         LDX     0,i
         STX     debutLi,s
         STX     finLi,s
         BR      parcour
  
invalide:STRO    msgInv,d
         LDA     hpPtr,d     ;Liberer et effacer le heap de l'evenement invalide
         SUBA    mTaille,i
         STA     hpPtr,d
         LDA     effaceM,d
         STA     hpPtr,n
         ADDSP   12,i        ;#element #newDebut #newFin #debutLi #finLi #elemPrec
         LDA     0,i
         STA     valRLoc,s   ;return 0
         RET0
         
succes:  ADDSP   12,i        ;#element #newDebut #newFin #debutLi #finLi #elemPrec
         LDA     1,i         
         STA     valRLoc,s   ;Return 1 
         RET0
         
msgInv:  .ASCII  "Planification de l'événement entré impossible.\n\x00"

element: .EQUATE 0           ;#2d
newDebut:.EQUATE 2          ;#2d
newFin:  .EQUATE 4          ;#2d 
debutLi: .EQUATE 6          ;#2d
finLi:   .EQUATE 8          ;#2d
elemPrec:.EQUATE 10          ;#2d        
headLoc: .EQUATE 14          ;#2d
newEvLoc:.EQUATE 16          ;#2d
valRLoc: .EQUATE 6           ;#2d
effaceM: .BLOCK  10

;Fonction Creer() Cette fonction cree un nouveau maillon, sauvegarde les 
;valeurs entree par l'utilisateur et retourne l'adresse de l'evenement cree ou 0 
;si une des donnee entree est invalide.
;OUT : X = Adresse de l'evenement cree ou 0 si aucun evenement est cree
Creer:   STRO    affJour,d
         DECI    chJour,d    ;chJour = jours entrer par l'utilisateur
         LDA     chJour,d    ;A = chJour
         CPA     jourMin,i   ;Validation A >= 1 && A <= 7
         BRLT    choixInv
         CPA     jourMax,i
         BRGT    choixInv
         STRO    affHDebu,d  
         DECI    chHeure,d   ;chHeure = heure debut entre par l'utilisateur
         LDA     chHeure,d   ;A = chHeure
         CPA     tempMin,i   ;Validation A >= 0 && a <= 1440
         BRLT    choixInv
         CPA     tempMax,i
         BRGT    choixInv
         STRO    affDuree,d
         DECI    chDuree,d   ;chDuree = duree entree par l'utilisateur
         LDA     chDuree,d   ;A = chDuree
         CPA     tempMin,i   ;Validation A >= 0 && a <= 1440
         BRLT    choixInv
         CPA     tempMax,i
         BRGT    choixInv
         LDA     mTaille,i   ;A = taille d'un maillon = 10
         CALL    new         ;Cree nouveau maillon, X = Addresse du maillon
         LDA     chJour,d    ;Sauvegarde des valeur chJour, chHeure, chDuree                              
         STA     mJour,x     ;dans le maillon.
         LDA     chHeure,d
         STA     mHDebut,x
         LDA     chDuree,d
         STA     mDuree,x
         LDA     0,i         ;Initialise suivant et precedant du maillon a 0
         STA     mSuivant,x
         STA     mPrec,x         
         LDA     head,d      ;Verifie si head existe deja
         CPA     0,i
         BRNE    skipHead    
         STX     head,d      ;Sinon le maillon actuel est le head
skipHead:LDA     head,d      ;A = addresse de head
         RET0
                  
choixInv:STRO    msgErrFo,d  ;L'entree de l'utilisateur est invalide, 
         LDA     0,i         ;valeur reinitialise et retour
         STA     chJour,d
         STA     chHeure,d
         STA     chDuree,d 
         RET0

chJour:  .BLOCK  2
chHeure: .BLOCK  2
chDuree: .BLOCK  2
jourMin: .EQUATE 1
jourMax: .EQUATE 7
tempMin: .EQUATE 0
tempMax: .EQUATE 1440
affJour: .ASCII  "Événement\nJour : \x00" 
affHDebu:.ASCII  "Heure de début : \x00"
affDuree:.ASCII  "Durée : \x00"
msgErrFo:.ASCII  "Erreur de format\n\x00"
head:    .BLOCK 2            ;#2h tete de liste

;Fonction AffAgd(Event* Head) Cette fonction Affiche tout les evenements 
;enregistrer dans la liste en format texte (jour, heure de debut et duree).
;IN: A = Adresse de Head
;OUT: void
AffAgd:  CPA     0,i         ;Verifie un evenement existe dans la liste
         BREQ    finAff      ;sinon on sort
         STRO    msgAff,d    
bclAff:  STA     eAAffic,d   ;Sauvegarde de l'evenement a afficher
         CALL    CDebFin     ;Calcul des valeur debut et duree
         STA     debAg,d     ;Load A et X pour envoyer a la fonction AffTxt()
         STX     finAg,d
         CALL    AffTxt      ;Appel de fonction AffTxt(debut, duree)
         LDA     eAAffic,d   ;Load l'evenement qui a ete afficher
         ADDA    mSuivant,i  ;A == l'element suivant de la liste
         STA     addCaseS,d  ;Sauvegarde l'adresse de la case
         LDA     addCaseS,n  ;Load l'adresse de l'evenement suivant
         CPA     0,i         ;Verifie si c'est la fin de la liste
         BREQ    finAff      ;Si oui, affichage terminer
         BR      bclAff      ;Sinon Continue d'afficher
finAff:  RET0 
msgAff:  .ASCII  "******************\n"
msgAff2: .ASCII  "*     Agenda     *\n"
msgAff3: .ASCII  "******************\n\x00"
debAg:   .BLOCK  2
finAg:   .BLOCK  2
eAAffic: .BLOCK  2
addCaseS:.BLOCK  2

;Fonction AffTxt(debut, duree) qui convertie les minutes debut et duree et 
;les affiche en format texte
;IN: A = debut de l'evenement, X = Duree de l'evenement
;OUT: void
AffTxt:  STA     finAffT,d   ;Sauvgegarde le debut de l'evenement en minutes
         SUBX    finAffT,d   ;La fin de l'evenement avec le debut == duree
         STX     finAffT,d   ;Sauvegarde de la duree de l'evenement.
         LDX     0,i
bclAffJ: CPA     1440,i      ;Boucle qui compte le nombre de jours complets
         BRLT    stroJour 
         SUBA    1440,i
         ADDX    1,i
         BR      bclAffJ
stroJour:CPX     0,i         ;Affichage du jour de la semaine.
         BREQ    lundi       ;0 = lundi 6 = dimanche
         CPX     1,i
         BREQ    mardi
         CPX     2,i
         BREQ    merc
         CPX     3,i
         BREQ    jeudi
         CPX     4,i
         BREQ    vendredi
         CPX     5,i
         BREQ    samedi
         CPX     6,i
         BREQ    dimanche
         BR      erreur      ;ne devrais jamais arriver

affHDeb: LDX     0,i         ;Affichage de l'heure de debut
bclAffH: CPA     60,i        ;Boucle de calcul du nombre d'heures
         BRLT    affHeure 
         SUBA    60,i
         ADDX    1,i
         BR      bclAffH
affHeure:STX     nbHDeb,d    ;Affichage de l'heure de debut a la console
         STA     nbMinDeb,d 
         DECO    nbHDeb,d    ;heure de debut
         CHARO   'h',i
         DECO    nbMinDeb,d  ;minute de debut

affHFin: LDA     finAffT,d   ;Affichage de la duree de l'evenement
         LDX     0,i
bclAffHF:CPA     60,i        ;Boucle de calcul du nombre d'heures
         BRLT    affMFin 
         SUBA    60,i
         ADDX    1,i
         BR      bclAffHF            

affMFin: STX     nbHFin,d    ;Affichage de la duree de l'evenement en heure
         STA     nbMinFin,d  ; et minutes a la console
         CHARO   ' ',i
         DECO    nbHFin,d    ;Heures
         CHARO   'h',i
         DECO    nbMinFin,d  ;minutes
         CHARO   '\n',i
         CHARO   '\n',i
         RET0

lundi:   STRO    affLun,d    ;Affichage du jour a la console et retour au 
         BR      affHDeb     ;calcul de heures.
mardi:   STRO    affMar,d
         BR      affHDeb
merc:    STRO    affMerc,d
         BR      affHDeb
jeudi:   STRO    affJeu,d
         BR      affHDeb
vendredi:STRO    affVend,d
         BR      affHDeb
samedi:  STRO    affSam,d
         BR      affHDeb
dimanche:STRO    affDim,d
         BR      affHDeb 
erreur:  STRO    errAff,d

errAff:  .ASCII  "Une erreur est survenue\n\x00"
affLun:  .ASCII  "Lundi \x00"
affMar:  .ASCII  "Mardi \x00"
affMerc: .ASCII  "Mercredi \x00"
affJeu:  .ASCII  "Jeudi \x00"
affVend: .ASCII  "Vendredi \x00"
affSam:  .ASCII  "Samedi \x00"
affDim:  .ASCII  "Dimanche \x00"
nbJAfTx:.BLOCK   2
finAffT:.BLOCK   2
nbHDeb:  .BLOCK  2
nbMinDeb:.BLOCK  2
nbHFin:  .BLOCK  2
nbMinFin:.BLOCK  2

;Fonction CDebFin(Addresse event) calcul de temps en minutes
;Cette fonction calcul l'heure de debut et l'heure de fin d'un evenement 
;en minutes.
;IN: A = adresse de l'evenement
;OUT: A = debut de l'evenement, X = Fin de l'evenement
CDebFin: STA     eventCal,d  ;Sauvegarde l'adresse de l'evenement
         LDA     eventCal,n  ;Load le nombre de jour 
         STA     nbJour,d    ;Sauvegarde le nombre jde jour
bclJour: LDA     nbJour,d    ;Boucle qui ajoute 1440 minutes a chaque jours
         SUBA    1,i
         CPA     0,i         ;Termine si zero jours restant a ajouter
         BRLE    contCalc
         STA     nbJour,d
         LDA     debut,d
         ADDA    1440,i
         STA     debut,d
         BR      bclJour         
contCalc:LDA     eventCal,d  ;Cherche l'addresse de l'evenement
         ADDA    mHDebut,i   ;Cherche la case contenant le nombre de minutes
         STA     caseDebu,d
         LDA     caseDebu,n  ;Load le nombre de minutes
         ADDA    debut,d     ;Ajoute les minutes au total 
         STA     debut,d     ;On obtient le debut en minutes
         LDX     mDuree,i    ;trouve la duree de l'evenement
         ADDX    eventCal,d
         STX     caseDure,d 
         LDX     caseDure,n
         ADDX    debut,d     ;ajoute au total debut
         STX     caseTamp,d  ;X = minutes correspondant a la fin de l'evenement
         LDX     0,i         ;Reinitialisation des variables locales
         STX     debut,d
         STX     fin,d
         LDX     caseTamp,d
         RET0
eventCal:.BLOCK  2
debut:   .BLOCK  2
fin:     .BLOCK  2
nbJour:  .BLOCK  2
caseDebu:.BLOCK  2
caseDure:.BLOCK  2
caseTamp:.BLOCK   2
;******* Structure d'un evenement
; Une liste est constituée d'une chaîne de maillons.
; Chaque maillon contient un jour, une duree, une heure de debut,
;  l'adresse de l'evenement precedant et l'adresse de l'evenement suivant.
; La fin de la liste est marquée arbitrairement par l'adresse 0
mJour:   .EQUATE 0           ; #2d valeur de l'élément jour dans maillon
mHDebut: .EQUATE 2           ; #2d valeur de l'élément heureDebut dans maillon
mDuree:  .EQUATE 4           ; #2d valeur de l'élément duree dans maillon
mSuivant:.EQUATE 6           ; #2h maillon suivant 0 si fin de liste
mPrec:   .EQUATE 8           ; #2h maillon precedant 0 si debut de liste
mTaille: .EQUATE 10          ; taille d'un maillon en octets
;
;******* operator new
;        Precondition: A contains number of bytes
;        Postcondition: X contains pointer to bytes
new:     LDX     hpPtr,d     ;returned pointer
         ADDA    hpPtr,d     ;allocate from heap
         STA     hpPtr,d     ;update hpPtr
         RET0                
hpPtr:   .ADDRSS heap        ;address of next free byte
heap:    .BLOCK  500       ; first bytes in the heap

         .end
