.data

#MESSAGES D'INTERACTION AVEC L'UTILISATEUR:
#Demande de saisie
ouverture_fichier: .asciiz "Saisir le nom du fichier a compresser: "
taille_TR: .asciiz "Saisir la taille du tampon de recherche: "
taille_TL: .asciiz "Saisir la taille du tampon de lecture: "
#Indication du debut de la compression
progress: .asciiz "La compression est en cours. Veuillez patienter...\n"
#Affiche si une erreur survient a l'ouverture du fichier a compresser
fnf: .asciiz "Fichier introuvable!"

#DEFINITION DES VARIABLES UTILISEES DANS LA SUITE DU CODE:
#L'espace memoire pour stocker le nom du fichier a compresser
fichier_a_compresser: .space 30
#Le nom du fichier de sortie et son extension (fichier compresse)
fichier_sortie: .space 31
extension: .ascii "lz77"
#Le tampon de recherche (taille maximale 500)
tampon_R: .space 500
#Le tampon de lecture (taille maximale 500)
tampon_L: .space 500
#Une copie du tampon de recherche
copie_tampon_R: .space 500
#Une copie du tampon de lecture
copie_tampon_L: .space 500
#Espace memoire pour stocker le contenu du fichier a compresser (taille par defaut: 2048 bits)
buffer: .space 10000
#Espace memoire pour stocker le resultat de la compression qui sera ensuite enrigistre dans le fichier de sortie (taille par defaut: 4096 bits)
bufferResult: .space 10000

.text
.globl __start

__start:

#Demande de saisie de la taille des tampons
la $a0 taille_TR
li $v0 4
syscall

li $v0 5
syscall
move $s4 $v0


la $a0 taille_TL
li $v0 4
syscall

li $v0 5
syscall
move $s5 $v0


#Initialisation des registres permanents:
#Ces registres conservent la meme valeur tout au long du code:
li $s0 0 #Position suivante vide dans le "bufferResult" pour enregistrer un caractere

#Demande d'entrer le nom du fichier a compresser:
la $a0 ouverture_fichier
li $v0 4
syscall

#Lecture de la chaine de caracteres:
la $a0 fichier_a_compresser
li $a1 30 #longueur maximum du nom de fichier
li $v0 8
syscall

#Message indiquant le debut du processus de compression:
la $a0 progress
li $v0 4
syscall

jal OuvrirPourLire #Ouverture du fichier a compresser

jal GenererNomFichierSortie #Generer un nom du fichier de sortie identique a celui d'entree a l'extension pres

jal OuvrirPourEcrire #Ouverture/Creation du fichier de sortie

#Enregistrement du contenu du fichier a compresser dans la variable "buffer":
ChargerBuffer:
move $a0 $s6
la $a1 buffer
li $a2 9999
li $v0 14
syscall

#Chargement initial des tampons:
li $a0 0 #position 0 dans le "buffer"
jal ChargerTampons

#Boucle de compression:
Compresser:
jal TamponLectureEstVide #Verifier si le tampon de lecture n'est pas vide
bne $v0 0 DechargerBuffer #Si oui alors on sort de la boucle
move $a0 $s1 #sinon, on passe la valeur de decalage de la tete de lecture par rapport a la position precedente a l'argument $a0
jal RechercheMotif #recherche de motif dans le tampon de recherche indentique a celui au debut du tampon de lecture
j Compresser

#Enregistrement du resultat de la compression dans le fichier de sortie:
DechargerBuffer:
move $a0 $s7 #on fourni a l'appel systeme le descripteur du fichier de sortie
la $a1 bufferResult #ainsi que le buffer a enregistrer
move $a2 $s0 #et la longueur du texte a enregistrer
li $v0 15
syscall

jal FermerTout #Fermeture des fichiers de source et de sortie 

j Exit #Fin de l'execution

Exit:
li $v0 10
syscall

#FONCTION: Ouverture du fichier a compresser (mode lecture)
#PARAMETRES: aucun
#PRECONDITIONS: nom du fichier < 30 bits (caracteres)
OuvrirPourLire:
#Recherche et supression du caractere \0 a la fin du nom de fichier lu depuis l'entree utilisateur
xor $a2, $a2, $a2 #on iniatilse a2 a 0
loop:
    lbu $a3, fichier_a_compresser($a2)  
    addiu $a2, $a2, 1
    bnez $a3, loop       # boucle pour rechercher le caractere \0
    beq $a1, $a2, skip   # si le nombre de caractere=30 on ne fait rien
    subiu $a2, $a2, 2    # sinon on supprime le dernier caractere
    sb $0, fichier_a_compresser($a2)     # et on le remplace par le caractere NULL
skip:
la $a0 fichier_a_compresser #nom du fichier a ouvrir
li $a1 0 #0: pour la lecture
li $a2 0 #0: mode est ignore
li $v0 13 #ouverture
syscall
move $s6 $v0 #sauvegarde du descripteur du fichier dans $s6
blt $v0 0 erreur #si le code do sortie est negatif, une erreur est survenue
jr $ra

#FONCTION: Generer un nom du fichier de sortie identique a celui d'entree a l'extension pres
#PARAMETRES: aucun
#PRECONDITIONS: nom du fichier < 30 bits (caracteres)
GenererNomFichierSortie:
li $t0 0
BoucleParcours:
lb $t1 fichier_a_compresser($t0)
beq $t1 0 FinParcours
sb $t1 fichier_sortie($t0)
addi $t0 $t0 1
j BoucleParcours
FinParcours:
subi $t0 $t0 3
li $t2 0
MettreExtension:
beq $t2 4 FinGenerer
lb $t1 extension($t2)
sb $t1 fichier_sortie($t0)
addi $t0 $t0 1
addi $t2 $t2 1
j MettreExtension
FinGenerer:
jr $ra

#FONCTION: Ouverture/Creation du fichier de sortie (mode ecriture)
#PARAMETRES: aucun
#PRECONDITIONS: aucune
OuvrirPourEcrire: #Fonction d'ouverture de fichier pour l'ecriture
la $a0 fichier_sortie #nom du fichier a ouvrir
li $a1 1 #1: pour la lecture
li $a2 0 #0: mode est ignore
li $v0 13 #ouverture
syscall
move $s7 $v0 #sauvegarde du descripteur du fichier dans $s7
blt $v0 0 erreur #si le code do sortie est negatif, une erreur est survenue
jr $ra 

#Affichage d'un message d'erreur lors qu'un probleme se produit lors de l'ouverture d'un des fichiers
erreur:
la $a0 fnf
li $v0 4
syscall

#FONCTION: Fermeture des fichiers de source et de sortie
#PARAMETRES: $s6 = le descripteur du fichier de source
#	         $s7 = le descripteur du fichier de sortie
#PRECONDITIONS: aucune
FermerTout:
move $a0 $s6
li $v0 16
syscall
li $v0 16
syscall
jr $ra

#FONCTION: Chargement des tampons
#PARAMETRES: $a0 = la position initiale pour la tete de lecture
#PRECONDITIONS: aucune
ChargerTampons:
#Prologue:
subu $sp $sp 32
sw $t3 28($sp)
sw $t2 24($sp)
sw $t1 20($sp)
sw $t0 16($sp)
sw $s5 12($sp)
sw $s4 8($sp)
sw $a0 4($sp)
sw $ra 0($sp)
#Corps:
move $t0 $a0
li $t1 0
add $t1 $t0 $s5
li $t3 0
#Chrgement du tampon de lecture a partir du buffer:
ChargerTamponLecture:
bge $t0 $t1 FinChargementTamponLecture
lb $t2 buffer($t0)
sb $t2 tampon_L($t3)
addi $t0 $t0 1
addi $t3 $t3 1
j ChargerTamponLecture
#Reinitialisation des compteurs et registres temporaires:
FinChargementTamponLecture:
move $t1 $a0
sub $t0 $t1 $s4
li $t3 0
#Chrgement du tampon de recherche a partir du buffer:
ChargerTamponRecherche:
bge $t0 $t1 Epilogue
ChargerZeros: #Remplacement des caracteres NULL dans le tampon de recherche par des espaces (code 32 en ASCII)
bge $t0 0 ContinueCharger
li $t2 32
sb $t2 tampon_R($t3)
addi $t3 $t3 1
addi $t0 $t0 1
j ChargerZeros
ContinueCharger:
lb $t2 buffer($t0)
sb $t2 tampon_R($t3)
addi $t3 $t3 1
addi $t0 $t0 1
j ChargerTamponRecherche
#Epilogue:
Epilogue:
lw $t3 28($sp)
lw $t2 24($sp)
lw $t1 20($sp)
lw $t0 16($sp)
lw $s5 12($sp)
lw $s4 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 32
jr $ra

#FONCTION: Comparaison de deux chaines de caracteres (des copies des tampons)
#PARAMETRES: $a0 = la longueur des chaines a comparer
#PRECONDITIONS: $a0 doit etre plus petit ou egal a la taille du plus petit des tampons
ComparerChaines:
#Prologue:
subu $sp $sp 8
sw $a0 4($sp)
sw $ra 0($sp)
#Corps:
li $t0 0 #initialiser le compteur a 0
move $t1 $a0
Comparaison:
bge $t0 $t1 SontEgaux
lb $t2 copie_tampon_L($t0)
lb $t3 copie_tampon_R($t0)
bne $t2 $t3 PasEgaux
addi $t0 $t0 1
j Comparaison

#Differentes sorties possibles de la boucle de comparaison:
PasEgaux:
li $v0 0
j EpilogueComparaison

SontEgaux:
li $v0 1
j EpilogueComparaison

#Epilogue:
EpilogueComparaison:
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 8 
jr $ra

#FONCTION: Extraction d'une sous-chaine a partir du tempon de lecture (fonction auxiliaire pour la recherche de motifs)
#PARAMETRES: $a0 = la position du debut de l'extraction dans le tampon de lecture
#	         $a1 = la longueur de la sous-chaine a extraire
#PRECONDITIONS: aucune
SousChaineLecture:
#Prologue:
subu $sp $sp 24
sw $t2 20($sp)
sw $t1 16($sp)
sw $t0 12($sp)
sw $a1 8($sp) #longueur
sw $a0 4($sp) #position du debut
sw $ra 0($sp)
#Corps:
li $t0 0 #compteur a 0
move $t2 $a0
Extraction:
bge $t0 $a1 EpilogueSousChaine
lb $t1 tampon_L($t2)
sb $t1 copie_tampon_L($t0)
addi $t2 $t2 1
addi $t0 $t0 1
j Extraction

EpilogueSousChaine:
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp) #longueur
lw $a0 4($sp) #position du debut
lw $ra 0($sp)
addu $sp $sp 24
jr $ra

#FONCTION: Extraction d'une sous-chaine a partir du tempon de recherche (fonction auxiliaire pour la recherche de motifs)
#PARAMETRES: $a0 = la position du debut de l'extraction dans le tampon de recherche
#	         $a1 = la longueur de la sous-chaine a extraire
#PRECONDITIONS: aucune
SousChaineRecherche:
#Prologue:
subu $sp $sp 24
sw $t2 20($sp)
sw $t1 16($sp)
sw $t0 12($sp)
sw $a1 8($sp) #longueur
sw $a0 4($sp) #position du debut
sw $ra 0($sp)
#Corps:
li $t0 0 #compteur a 0
move $t2 $a0
ExtractionRecherche:
bge $t0 $a1 EpilogueSousChaineRecherche
lb $t1 tampon_R($t2)
sb $t1 copie_tampon_R($t0)
addi $t2 $t2 1
addi $t0 $t0 1
j ExtractionRecherche

EpilogueSousChaineRecherche:
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp) #longueur
lw $a0 4($sp) #position du debut
lw $ra 0($sp)
addu $sp $sp 24
jr $ra

#FONCTION: Recherche d'un motif extrait a partir du debut du tampon de lecture dans le tampon de recherche (par methode de comparaison de deux sous-chaines)
#PARAMETRES: $a1 = la longueur de la chaine (stocke dans la copie du tampon de lecture) a rechercher dans le tampon de recherche
#PRECONDITIONS: aucune
INDEX:
#Prologue:
subu $sp $sp 12
sw $s4 8($sp)
sw $a1 4($sp)
sw $ra 0($sp)
#Corps:
li $t6 0 #initialiser le compteur a 0
li $t7 0
sub $t7 $s4 $a1
BoucleIndex:
bgt $t6 $t7 ExistePas
move $a0 $t6
jal SousChaineRecherche
move $a0 $a1
jal ComparerChaines
beq $v0 1 Trouve
addi $t6 $t6 1
j BoucleIndex

#La sortie adoptee par la fonction INDEX si le motif a ete trouve dans le tampon de recherche
Trouve:
li $v0 1 #dans $v0 on renvoie 1 (TRUE)
move $v1 $t6 #dans $v1 on renvoie la position a la quelle le motif a ete trouve dans le tampon de recherche
j EpilogueIndex

#La sortie adoptee par la fonction INDEX si le motif n'a pas ete trouve dans le tampon de recherche
ExistePas:
li $v0 0 #dans $v0 on renvoie 0 (FALSE)
li $v1 0 #lorsqu'on trouve pas de motif correspondant dans le tampon de recherche on renvoie 0 pour la position
j EpilogueIndex

EpilogueIndex:
lw $s4 8($sp)
lw $a1 4($sp)
lw $ra 0($sp)
addu $sp $sp 12
jr $ra

#FONCTION: Ajout d'un caractere dans le bufferResult
#PARAMETRES: $a2 = le caractere a ajouter
#PRECONDITIONS: aucune
AppendCharacterToResult:
#Prologue:
subu $sp $sp 8
sw $a2 4($sp)
sw $ra 0($sp)
sb $a2 bufferResult($s0)
addi $s0 $s0 1 #on augmente la taille utilisee du buffer d'un bit
#Epilogue:
lw $a2 4($sp)
lw $ra 0($sp)
addu $sp $sp 8
jr $ra

#FONCTION: Recherche d'un motif extrait a partir du debut du tampon de lecture dans le tampon de recherche (par methode de comparaison de deux sous-chaines)
#PARAMETRES: $a0 = la position du milieu de la tete de lecture
#PRECONDITIONS: aucune
RechercheMotif:
#Prologue:
subu $sp $sp 36
sw $a2 32($sp)
sw $s3 28($sp)
sw $s2 24($sp)
sw $t2 20($sp)
sw $t1 16($sp)
sw $t0 12($sp)
sw $a1 8($sp)
sw $a0 4($sp)
sw $ra 0($sp)
#Corps:
li $t0 0 #initialiser le compteur a 0
move $t1 $s5
BoucleMotif:
blt $t1 1 PasDeMotif #Tant que le motif se trouvant au debut du tampon de lecture a au moins 1 bit de taille on recherche un motif qui lui correspon dans le tampon de recherche
move $a1 $t1
li $a0 0
jal SousChaineLecture
move $a1 $t1
jal INDEX
move $s3 $v1
move $s2 $t1
beq $v0 1 MotifTrouve
subi $t1 $t1 1
j BoucleMotif

PasDeMotif: #si on ne trouve pas de motif correspondant on ajout le triplet (0,0,c) au bufferResult
li $a2 0
jal AppendCharacterToResult

li $a2 0
jal AppendCharacterToResult

li $t0 0
lb $a2 tampon_L($t0) #le premier caractere du tampon de recherche
jal AppendCharacterToResult

li $t0 0
lw $a0 4($sp)
addi $a0 $a0 1 #on decale la tete de lecture d'un cran
move $s1 $a0
jal ChargerTampons
j EpilogueMotif

MotifTrouve: #si le motif correspondant se trouve dans le tampon de recherche on ajout un triplet (p,l,c) au bufferResult
sub $s3 $s4 $s3 #Pour avoir la position du motif correspondant dans le tampon de recherche a partir du debut du tampon de lecture on soustrait a la taille du tampon de recherche la position du motif correspondant par rapport au debut du tampon de recherche
move $a2 $s3
#addi $a2 $a2 48 #Formattage ASCII
jal AppendCharacterToResult

move $a2 $s2 #La longueur du motif trouve
#addi $a2 $a2 48 #Formattage ASCII
jal AppendCharacterToResult

lb $a2 tampon_L($s2) #Le caractere suivant dans le tampon de lecture
jal AppendCharacterToResult

li $t0 0
lw $a0 4($sp)
addi $t0 $s2 1
add $a0 $a0 $t0 #Decalage de la tete de lecture de l+1 positions
move $s1 $a0
jal ChargerTampons
j EpilogueMotif

EpilogueMotif:
lw $a2 32($sp)
lw $s3 28($sp)
lw $s2 24($sp)
lw $t2 20($sp)
lw $t1 16($sp)
lw $t0 12($sp)
lw $a1 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 36
jr $ra

#FONCTION: Test booleen de vacuite du tampon de lecture
#PARAMETRES: aucun
#PRECONDITIONS: aucune
TamponLectureEstVide:
#Prologue:
subu $sp $sp 16
sw $t1 12($sp)
sw $t0 8($sp)
sw $s5 4($sp)
sw $ra 0($sp)
#Corps:
li $t0 0
EstVideBoucle:
bge $t0 $s5 EstVide
lb $t1 tampon_L($t0)
bne $t1 0 NonVide #Des qu'on trouve un caractere qui n'est pas egal a 0 (qui n'est pas NULL/vide) on renvoie FALSE (valeur 0)
addi $t0 $t0 1
j EstVideBoucle
NonVide:
li $v0 0
j EpilogueVide
EstVide:
li $v0 1
j EpilogueVide
EpilogueVide:
lw $t1 12($sp)
lw $t0 8($sp)
lw $s5 4($sp)
lw $ra 0($sp)
addu $sp $sp 16
jr $ra
