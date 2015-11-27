.data

ouverture_fichier: .asciiz "Saisir le nom du fichier a compresser: "
fichier_a_compresser: .space 31
fichier_sortie: .asciiz "out.lz77"

tampon_R: .space 6
tampon_L: .space 5

buffer: .space 2048
fnf: .asciiz "NOT FOUND"
test: .asciiz "C:\\test.txt"

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

li $a0 12

jal ChargerTampons

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
bge $t1 $s5 Prologue
lb $t2 tampon_L($t1)
move $a0 $t2
li $v0 11
syscall
addi $t1 $t1 1
j ImpressionTamponLecture
#Prologue:
Prologue:
lw $s5 12($sp)
lw $s4 8($sp)
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 16
jr $ra
