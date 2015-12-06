.data

ouverture_fichier: .asciiz "Enter name of the file you want to be compressed: "
progress: .asciiz "File compression in progress. This may take several minutes or hours depending on source file size. Please wait...\n"
fichier_a_compresser: .space 31
fichier_sortie: .asciiz "out.lz77"

tampon_R: .space 6
tampon_L: .space 5
copie_tampon_L: .space 5
copie_tampon_R: .space 6

buffer: .space 2048
bufferResult: .space 4096
fnf: .asciiz "NOT FOUND"

.text
.globl __start

__start:

li $s5 5
li $s4 6

li $s0 0

#Demande d'entrer le nom du fichier a compresser:
la $a0 ouverture_fichier
li $v0 4
syscall

#Lecture de la chaine de caracteres:
la $a0 fichier_a_compresser
li $a1 30 #longueur maximum du nom de fichier
li $v0 8
syscall

la $a0 progress
li $v0 4
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
move $a2 $s0
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
ChargerTamponRecherche:
bge $t0 $t1 Epilogue
ChargerZeros:
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
addi $t0 $t0 1
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
bgt $t6 $t7 ExistePas #CHGT AU PIF!!!!!
move $a0 $t6
jal SousChaineRecherche
move $a0 $a1
jal ComparerChaines
beq $v0 1 Trouve
addi $t6 $t6 1
j BoucleIndex

Trouve:
li $v0 1
move $v1 $t6
j EpilogueIndex

ExistePas:
li $v0 0
li $v1 0
j EpilogueIndex

EpilogueIndex:
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
sb $a2 bufferResult($s0)
addi $s0 $s0 1
#Epilogue:
lw $a2 4($sp) #char to append
lw $ra 0($sp)
addu $sp $sp 8
jr $ra

#Recherche du motif le plus long a compresser
#Params:
#	-> $a0: position du milieu de la tete de lecture
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
li $t0 0 #compteur a 0
move $t1 $s5
BoucleMotif:
blt $t1 1 PasDeMotif
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

PasDeMotif:
li $a2 40
jal AppendCharacterToResult
li $a2 48
jal AppendCharacterToResult
li $a2 44
jal AppendCharacterToResult
li $a2 48
jal AppendCharacterToResult
li $a2 44
jal AppendCharacterToResult
li $t0 0
lb $a2 tampon_L($t0)
jal AppendCharacterToResult
li $a2 41
jal AppendCharacterToResult
li $t0 0
lw $a0 4($sp)
addi $a0 $a0 1
move $s1 $a0
jal ChargerTampons
j EpilogueMotif

MotifTrouve:
li $a2 40
jal AppendCharacterToResult
sub $s3 $s4 $s3
move $a2 $s3
addi $a2 $a2 48
jal AppendCharacterToResult
li $a2 44
jal AppendCharacterToResult
move $a2 $s2
addi $a2 $a2 48
jal AppendCharacterToResult
li $a2 44
jal AppendCharacterToResult
lb $a2 tampon_L($s2)
jal AppendCharacterToResult
li $a2 41
jal AppendCharacterToResult
li $t0 0
lw $a0 4($sp)
addi $t0 $s2 1
add $a0 $a0 $t0
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

#Verifie si tampon_L est vide
#Params: -> $s5: longueur du tampon_L
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
lw $t1 12($sp)
lw $t0 8($sp)
lw $s5 4($sp)
lw $ra 0($sp)
addu $sp $sp 16
jr $ra
