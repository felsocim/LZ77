.data

ouverture_fichier: .asciiz "Saisir le nom du fichier a compresser: "
fichier_a_compresser: .space 30
fichier_sortie: .asciiz "out.lz77"

buffer: .space 2048
fnf: .asciiz "NOT FOUND"
test: .asciiz "C:\\test.txt"

.text
.globl __start

__start:

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

move $a0 $s6
la $a1 buffer
li $a2 2000
li $v0 14
syscall

la $t0 buffer
lb $a0 5($t0)
li $v0 11
syscall

jal FermerTout 

j Exit

Exit:
li $v0 10
syscall

OuvrirPourLire: #Fonction d'ouverture de fichier pour la lecture
la $a0 test #nom du fichier a ouvrir
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