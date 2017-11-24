.data

fichier_sortie: .space 30

extension: .ascii "txt"

progress: .asciiz "Decompression en cours. Veuillez patienter...\n"

Tampon_L:
	.space 3

fnf: .asciiz "Fichier introuvable"

taille_TR: .asciiz "Saisir la taille du tampon de recherche: "

Tampon_R:
	.space 500

fichier_a_compresser: 
	.space 31

ouverture_fichier: .asciiz "Saisir le nom du fichier a decompresser: "

buffer: .space 10000	

Buffer_E:
	.space 10000
Buffer_tmp:
	.space 500

saut: .asciiz "\n"
.text
.globl __start

__start:

la $a0 taille_TR
li $v0 4
syscall

li $v0 5
syscall
move $s1 $v0

li $s0 0 #position a laquelle on plce les elements dans le buffer temporaire
li $s2 0 #position a laquelle on cherche les elements dans le buffer
li $v0 1

li $s4 0

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

jal GenererNomFichierSortie

jal OuvrirPourEcrire

#Lecture depuis le fichier
ChargerBuffer:
move $a0 $s6
la $a1 buffer
li $a2 9999
li $v0 14
syscall

loopMain:
jal chargerTamponLecture
jal estVide
beqz $v0 finLoopMain
jal traduitTriplet
j loopMain
finLoopMain:
li $t0 0
LastLoop:
bge $t0 $t5 finLastLoop
lb $t2 Tampon_R($t0)
sb $t2 Buffer_E($s0)
addi $t0 $t0 1
addi $s0 $s0 1
j LastLoop
finLastLoop:
jal DechargerBuffer
j Exit


Exit:
li $v0 10
syscall



#écrit dans le tampon de recherche les l elements stockes dans le tampon temporaire
#donnée: $a2 = l
ecritureTamponRecherche:
	#initialisation
subu $sp $sp 8
sw $a2 4($sp)
sw $ra 0($sp)

li $t0 0 #initialisation de l'increment
addi $t1 $a2 1
sub $t1 $s1 $t1
	#corps de la fonction
loopEcritureTamponRecherche:
bge $t0 $a2 FinLETP
lb $t2 Buffer_tmp($t0)
sb $t2 Tampon_R($t1)
addi $t0 $t0 1
addi $t1 $t1 1
addi $s4 $s4 1
j loopEcritureTamponRecherche
FinLETP:
la $a0 saut
li $v0 4
syscall
lw $a2 4($sp)
lw $ra 0($sp)
addu $sp $sp 8
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
subi $t0 $t0 4
li $t2 0
MettreExtension:
beq $t2 3 FinGenerer
lb $t1 extension($t2)
sb $t1 fichier_sortie($t0)
addi $t0 $t0 1
addi $t2 $t2 1
j MettreExtension
FinGenerer:
sb $zero fichier_sortie($t0)
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

OuvrirPourLire: #Fonction d'ouverture de fichier pour la lecture
xor $a2, $a2, $a2 #on iniatilse a2 a 0
loop:
    lbu $a3, fichier_a_compresser($a2)  
    addiu $a2, $a2, 1
    bnez $a3, loop       # boucle pour rechercher le caractere NULL
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
blt $v0 0 erreur
jr $ra


#fonction decalalant les elements du bufffer de recherche de l+1 position vers la gauche
#arg = $a2 = l
decalage:
	#initialisation
subu $sp $sp 8
sw $a2 4($sp)
sw $ra 0($sp)	

la $t0 ($a2)
addi $t0 $t0 1 #on a $t0 = l + 1
sub $t0 $s1 $t0 # on a $t0 = nombre d'element a decaler
addi $t4 $a2 1  #intialisation de l'adresse ermettant de connaitre la position de l'element a decaler
li $t2 0  #initialisation de l'adresse permettant de connaitre l'emplacement ou on va ajouter l'element a deplacer dans le buffer de lecture

	#corps de la fonction
loopDecalage:
beqz $t0 findecalage
lb $t3 Tampon_R($t4) #on met dans $t3 l'element a deplacer
sb $t3 Tampon_R($t2) #on met $t3 a la bonne position
addi $t4 $t4 1
addi $t2 $t2 1
subi $t0 $t0 1
addi $s4 $s4 1
j loopDecalage
findecalage:
lw $a2 4($sp)
lw $ra 0($sp)
addu $sp $sp 8
jr $ra

#fonction revoyant 0 si le tampon de lecture est vide, sinon 1
estVide:

	#initialisation
subu $sp $sp 4
sw $ra 0 ($sp)


li $t0 0 #on initialise la valeur de l'increment a 0

	#corps de la fonction
loopestVide:
bge $t0 3 EstVide
lb $t1 Tampon_L($t0)
bne $t1 0 NonVide #Des qu'on trouve un caractere qui n'est pas egal a 0 (qui n'est pas NULL/vide) on renvoie FALSE (valeur 0)
addi $t0 $t0 1
j loopestVide
NonVide:
li $v0 1
j EpilogueVide
EstVide:
li $v0 0
j EpilogueVide
EpilogueVide:
lw $ra 0($sp)
addu $sp $sp 4
jr $ra


#fonction placant les l+1 element du tampon de recherche dans le buffer d'ecriture en position $s0
# donnnee l= $a2, $s0 -> modifie $s0, $s0= $s0 + l+1
retenir:

	#initialisation
subu $sp $sp 8
sw $a2 4($sp)
sw $ra 0($sp)

addi $a2 $a2 1
li $t0 0 #initialisation de l'increment

	#corps de la fonction
loopRetenir:
bge $t0 $a2 finLoop
lb $t1 Tampon_R($t0) #on place dans $t1 l'element a recopier
sb $t1 Buffer_E($s0)
addi $t0 $t0 1
addi $s0 $s0 1
j loopRetenir
	#epilogue
finLoop:
lw $ra 0($sp)
lw $a2 4($sp)
addu $sp $sp 8
jr $ra


#fonction recopiant les l+1 element dans le tampon de recherche.
#en argument : p=$a1,l=$a2 et c=$a3:
traduitTriplet:

	#intialisation
subu $sp $sp 16
sw $a3 12($sp)
sw $a2 8($sp)
sw $a1 4($sp)
sw $ra 0($sp)

la  $t1 ($a2) # $t1 est une copie de $a2 que l'on va modifier plusierus fois
sub $t0 $s1 $a1 #on place dans $t0 la valeur correspondant a la position du premier caractere correspondant a l'occurence trouve, $s1 correspond à la taille du buffer de recherche  
li $s3 0 #ce registre nous sert a ecrire dans le buffer_tmp a la bonne place 

	#corps de la fonction

#tout d'abord on place les element a recopier dans le buffer temporaire
loopRecopiage:
beqz $t1 finRecopiage
lb $t2 Tampon_R($t0)
sb $t2 Buffer_tmp($s3)
addi $s3 $s3 1
addi $t0 $t0 1
subi $t1 $t1 1
jal loopRecopiage
finRecopiage:
blt $s4 $s1 finDecale
jal retenir	#on place les elements amenes a disparaitre dans le tampon d'ecriture
finDecale:
jal decalage	#on decale les l+1 premiers elements du tampon de recherche
jal ecritureTamponRecherche #on ecrit les elements stockes dans le tampon temporaire dans le tampon de lecture
subi $t4 $s1 1
sb $a3 Tampon_R($t4) #on ecrit le caractere c dans le tampon de recherche
addi $s4 $s4 1

FinIR2:
	#Epilogue
lw $a3 12($sp)
lw $a2 8($sp)
lw $a1 4($sp)
lw $ra 0($sp)
addu $sp $sp 16
la $t5 ($a2) 
sub $t5 $s1 $t5
jr $ra

chargerTamponLecture:
	#initialisation
subu $sp $sp 4
sw $ra 0($sp)

li $t1 0
	#corps de la fonction
loopCTL:
bge $t1 3 finCTL
lb $t4 buffer($s2)
sb $t4 Tampon_L($t1)
addi $t1 $t1 1
addi $s2 $s2 1
j loopCTL
	#Epilogue
finCTL:
lw $ra 0($sp)
addu $sp $sp 4
lb $a1 Tampon_L+0
lb $a2 Tampon_L+1
lb $a3 Tampon_L+2
jr $ra

DechargerBuffer:
move $a0 $s7
subi $t7 $s1 1
la $a1 Buffer_E($t7)
sub $s0 $s0 $t7
move $a2 $s0
li $v0 15
syscall
jr $ra

erreur:
la $a0 fnf
li $v0 4
syscall
