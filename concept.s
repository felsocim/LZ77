.data

ouverture_fichier: .asciiz "Saisir le nom du fichier a compresser: "
fichier_a_compresser: .space 31
fichier_sortie: .asciiz "out.lz77"

tampon_R: .space 6
tampon_L: .space 5
copie_tampon_L: .space 5
copie_tampon_R: .space 6

buffer: .space 2048
bufferResult: .space 2048
fnf: .asciiz "NOT FOUND"
test: .asciiz "C:\\test.txt"
parentheseGauche: .ascii "("
parentheseDroite: .ascii ")"
comma: .ascii ","

.text
.globl __start

__start:

li $s5 5
li $s4 6

#Demande d'entrer le nom du fichier a compresser:
la $a0 ouverture_fichier
li $v0 4
syscall

#Lecture de la chaine de caracteres:
la $a0 fichier_a_compresser
li $a1 30 #longueur maximum du nom de fichier
li $v0 8
syscall

jal OuvrirPourLire

jal OuvrirPourEcrire

#Lecture depuis le fichier
ChargerBuffer:
move $a0 $s6
la $a1 buffer
li $a2 2000
li $v0 14
syscall

#Initialize buffer
li $a0 0
jal ChargerTampons

#Boucle de compression:
Compresser:
jal TamponLectureEstVide
bne $v0 0 DechargerBuffer
move $a0 $s1
jal RechercheMotif
j Compresser

#Ecriture dans le fichier:
DechargerBuffer:
move $a0 $s7
la $a1 bufferResult
li $a2 2000
li $v0 15
syscall


jal FermerTout 

j Exit

Exit:
li $v0 10
syscall

OuvrirPourLire: #Fonction d'ouverture de fichier pour la lecture
xor $a2, $a2, $a2 #on iniatilse a2 ? 0
loop:
    lbu $a3, fichier_a_compresser($a2)  
    addiu $a2, $a2, 1
    bnez $a3, loop       # boucle pour rechercher le caract?re NULL
    beq $a1, $a2, skip   # si le nombre de caract?re=30 on ne fait rien
    subiu $a2, $a2, 2    # sinon on supprime le dernier caract?re
    sb $0, fichier_a_compresser($a2)     # et on le remplace par le caract?re NULL
skip:
la $a0 fichier_a_compresser #nom du fichier a ouvrir
li $a1 0 #0: pour la lecture
li $a2 0 #0: mode est ignore
li $v0 13 #ouverture
syscall
move $s6 $v0 #sauvegarde du descripteur du fichier dans $s6
blt $v0 0 erreur
jr $ra

OuvrirPourEcrire: #Fonction d'ouverture de fichier pour l'ecriture
la $a0 fichier_sortie #nom du fichier a ouvrir
li $a1 1 #1: pour la lecture
li $a2 0 #0: mode est ignore
li $v0 13 #ouverture
syscall
move $s7 $v0 #sauvegarde du descripteur du fichier dans $s7
blt $v0 0 erreur
jr $ra 

erreur:
la $a0 fnf
li $v0 4
syscall

FermerTout:
move $a0 $s6
li $v0 16
syscall
li $v0 16
syscall
jr $ra

#Parametres -> a0: position initiale
ChargerTampons:
#Prologue:
subu $sp $sp 16
sw $s5 12($sp)
sw $s4 8($sp)
sw $a0 4($sp)
sw $ra 0($sp)
#Corps:
move $t0 $a0
#add $t0 $t0 1
li $t1 0
add $t1 $t0 $s5
li $t3 0
#Chrgement du tampon de lecture a partir du buffer
ChargerTamponLecture:
bge $t0 $t1 FinChargementTamponLecture
lb $t2 buffer($t0)
sb $t2 tampon_L($t3)
addi $t0 $t0 1
addi $t3 $t3 1
j ChargerTamponLecture
#Reinitialisation des compteurs et registres temporaires
FinChargementTamponLecture:
move $t1 $a0
sub $t0 $t1 $s4
li $t3 0
#Chargement du tampon de recherche a partir du buffer
Decalage:
bge $t0 0 ChargerTamponRecherche
addi $t0 $t0 1
addi $t3 $t3 1
j Decalage
ChargerTamponRecherche:
bge $t0 $t1 FinChargement
lb $t2 buffer($t0)
sb $t2 tampon_R($t3)
addi $t3 $t3 1
addi $t0 $t0 1
j ChargerTamponRecherche
#Fin du chargement (teste d'impression)
FinChargement:
li $t0 0
li $t1 0
#Impression du tampon de recherche
ImpressionTamponRecherche:
bge $t0 $s4 ImpressionTamponLecture
lb $t2 tampon_R($t0)
move $a0 $t2
li $v0 11
syscall
addi $t0 $t0 1
j ImpressionTamponRecherche
#Impression du tampon de lecture
ImpressionTamponLecture:
bge $t1 $s5 Epilogue
lb $t2 tampon_L($t1)
move $a0 $t2
li $v0 11
syscall
addi $t1 $t1 1
j ImpressionTamponLecture
#Prologue:
Epilogue:
lw $s5 12($sp)
lw $s4 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 16
jr $ra

#Comparaison de deux chaines de caracteres
#Param: $a0 -> longueur des chaines de caracteres a comparer
ComparerChaines:
#Prologue:
subu $sp $sp 8
sw $a0 4($sp)
sw $ra 0($sp)
#Corps:
li $t0 0 #initialiser le compteur a 0
move $t1 $a0
Comparaison:
bge $t0 $t1 FinComparaison
lb $t2 copie_tampon_L($t0)
lb $t3 copie_tampon_R($t0)
bne $t2 $t3 PasEgaux
j Comparaison

#Epilogues:
PasEgaux:
li $v0 0
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 8
jr $ra

FinComparaison:
li $v0 1
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 8 
jr $ra

SousChaineLecture:
#Prologue:
subu $sp $sp 12
sw $a1 8($sp) #longueur
sw $a0 4($sp) #position du debut
sw $ra 0($sp)
#Corps:
li $t0 0 #compteur a 0
move $t2 $a0
Extraction:
bge $t0 $a1 FinExtraction
lb $t1 tampon_L($t2)
sb $t1 copie_tampon_L($t0)
addi $t2 $t2 1
addi $t0 $t0 1
j Extraction

FinExtraction:
li $t0 0
Impression:
bge $t0 $s4 EpilogueSousChaine
lb $t1 copie_tampon_L($t0)
move $a0 $t1
li $v0 11
syscall
addi $t0 $t0 1
j Impression

EpilogueSousChaine:
lw $a1 8($sp) 
lw $a0 4($sp) 
lw $ra 0($sp)
addu $sp $sp 12

jr $ra

SousChaineRecherche:
#Prologue:
subu $sp $sp 12
sw $a1 8($sp) #longueur
sw $a0 4($sp) #position du debut
sw $ra 0($sp)
#Corps:
li $t0 0 #compteur a 0
move $t2 $a0
ExtractionRecherche:
bge $t0 $a1 FinExtractionRecherche
lb $t1 tampon_R($t2)
sb $t1 copie_tampon_R($t0)
addi $t2 $t2 1
addi $t0 $t0 1
j ExtractionRecherche

FinExtractionRecherche:
li $t0 0
ImpressionRecherche:
bge $t0 $s5 EpilogueSousChaineRecherche
lb $t1 copie_tampon_R($t0)
move $a0 $t1
li $v0 11
syscall
addi $t0 $t0 1
j ImpressionRecherche

EpilogueSousChaineRecherche:
lw $a1 8($sp) 
lw $a0 4($sp) 
lw $ra 0($sp)
addu $sp $sp 12

jr $ra

#Fonction INDEX:
#Params: $s4 -> longueur du tampon R
#        $a1 -> longueur du string a comparer (copie_tampon_L)
INDEX:
#Prologue:
subu $sp $sp 12
sw $s4 8($sp)
sw $a1 4($sp)
sw $ra 0($sp)
#Corps:
li $t6 0 #compteur a 0
li $t7 0
sub $t7 $s4 $a1
BoucleIndex:
bge $t6 $t7 ExistePas
move $a0 $t6
jal SousChaineRecherche
move $a0 $a1
jal ComparerChaines
BoucleIndex2:
beq $v0 1 FinTotale
addi $t6 $t6 1
j BoucleIndex

FinTotale:
blt $t0 $t1 Trouve
j ExistePas

Trouve:
li $v0 1
lw $s4 8($sp)
lw $a1 4($sp)
lw $ra 0($sp)
addu $sp $sp 12
jr $ra

ExistePas:
li $v0 0
lw $s4 8($sp)
lw $a1 4($sp)
lw $ra 0($sp)
addu $sp $sp 12
jr $ra

#Appending character to resulting buffer
AppendCharacterToResult:
#Prologue:
subu $sp $sp 8
sw $a2 4($sp) #char to append
sw $ra 0($sp)
#Corps:
li $t0 0 #compteur a 0
AppendLoop:
lb $t1 bufferResult($t0)
beq $t1 0 Append
addi $t0 $t0 1
j AppendLoop
Append:
sb $a2 bufferResult($t0)
#Epilogue:
lw $a2 4($sp)
lw $ra 0($sp)
addu $sp $sp 8
jr $ra

#Recherche du motif le plus long a compresser
#Params:
#	-> $a0: position du milieu de la tete de lecture
RechercheMotif:
#Prologue:
subu $sp $sp 8
sw $a0 4($sp)
sw $ra 0($sp)
#Corps:
li $t0 0 #compteur a 0
move $t1 $s5
BoucleMotif:
blt $t1 1 PasDeMotif
move $a1 $t1
move $a0 $t0
jal SousChaineLecture
move $s2 $a1
jal INDEX
move $s3 $a0
bne $v0 1 MotifTrouve
addi $t0 $t0 1
add $t2 $t1 $t0
BoucleMotifImbriquee:
bgt $t2 $s5 BoucleMotif
move $a1 $t1
move $a0 $t0
jal SousChaineLecture
move $s2 $a1
jal INDEX
move $s3 $a0
bne $v0 1 MotifTrouve
addi $t0 $t0 1
addi $t2 $t2 1
j BoucleMotifImbriquee
subi $t1 $t1 1
j BoucleMotif

PasDeMotif:
la $a2 parentheseGauche
jal AppendCharacterToResult
li $a2 0
jal AppendCharacterToResult
la $a2 comma
jal AppendCharacterToResult
li $a2 0
jal AppendCharacterToResult
la $a2 comma
jal AppendCharacterToResult
li $t0 0
lb $a2 tampon_L($t0)
jal AppendCharacterToResult
la $a2 parentheseDroite
jal AppendCharacterToResult
li $t0 0
lw $a0 4($sp)
addi $a0 $a0 1
jal ChargerTampons
move $s1 $a0
j EpilogueMotif

MotifTrouve:
la $a2 parentheseGauche
jal AppendCharacterToResult
move $a2 $s3
jal AppendCharacterToResult
la $a2 comma
jal AppendCharacterToResult
move $a2 $s2
jal AppendCharacterToResult
la $a2 comma
jal AppendCharacterToResult
add $t0 $s2 $s3
lb $a2 tampon_L($t0)
jal AppendCharacterToResult
la $a2 parentheseDroite
jal AppendCharacterToResult
li $t0 0
lw $a0 4($sp)
addi $t0 $s2 1
add $a0 $a0 $t0
jal ChargerTampons
move $s1 $a0
j EpilogueMotif

EpilogueMotif:
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 8
jr $ra

#Verifie si tampon_L est vide
#Params: -> $s5: longueur du tampon_L
TamponLectureEstVide:
#Prologue:
subu $sp $sp 8
sw $s5 4($sp)
sw $ra 0($sp)
#Corps:
li $t0 0
EstVideBoucle:
bge $t0 $s5 EstVide
lb $t1 tampon_L($t0)
bne $t1 0 NonVide
addi $t0 $t0 1
j EstVideBoucle
NonVide:
li $v0 0
j EpilogueVide
EstVide:
li $v0 1
j EpilogueVide
EpilogueVide:
lw $s5 4($sp)
lw $ra 0($sp)
addu $sp $sp 8
jr $ra
