.data
.align 0

str_inserir: .asciiz "Digite a chave a ser inserida, ou -1 para finalizar a inser��o: "
str_remover: .asciiz "Digite a chave a ser removida, ou -1 para finalizar a remo��o: "
str_busca: .asciiz "Digite a chave a ser removida, ou -1 para finalizar a busca: "
str_chave: .asciiz "A chave "
str_busca_erro: .asciiz " n�o foi encontrada na tabela\n"
str_busca_encontrou: .asciiz " foi encontrada na tabela\n"

.align 2
.text
.globl main
main:

jal criar_tabela_hash

move $a0, $v0
jal inserir_hash
jal busca_hash
jal remover_hash
jal busca_hash

li $v0 10
syscall

# typedef struct node{
#		int val;
#		struct node *ant;
#		struct node *prox;
#	} NODE; => 12 bytes

#	NODE *tabela[16]; => 16 * 4 = 64 bytes
#Retorna em $v0 a tabela hash
criar_tabela_hash:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#Aloca��o de tabela[16]
	li $v0, 9 #servi�o para aloca��o de bytes
	li $a0, 64 # 4 * 16 = 64
	syscall
	move $t1, $v0
	
	li $t2, 16 #i = 16, usado no loop
	move $t3, $v0 #usado para controlar a inser��o no vetor	
loop_criar_tabela:
	 beq $zero, $t2, fim_loop_criar # while(i != 0)
	
	 li $v0, 9
	 li $a0, 12
	 syscall
	 
	 li $t5, -1 
	 sw $t5, 0($v0) # node->val = -1,  (-1) marca que � n� cabe�a
	 sw $v0, 4($v0) # node->ant = node =>lista circular
	 sw $v0, 8($v0)	# node->prox = node => lista circular
	 
	 sw $v0, 0($t3)
	 addi $t3, $t3, 4 #avan�a uma posi��o no vetor(4 bytes)
	 addi $t2, $t2, -1 #i = i -1
	 
	 j loop_criar_tabela
	 
fim_loop_criar:	
	move $v0, $t1 # A fun��o retorna tabela[16]
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

#Parametro $a0 - Tabela Hash
inserir_hash:
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)

	move $t7, $a0 #$t7 = tabela hash
	li $t2, 16 #tamanho da hash
	
loop_inserir:
	li $v0, 4 #C�digo para imprimir String
	la $a0, str_inserir
	syscall
	
	li $v0, 5 #C�digo para ler inteiro
	syscall
	move $t1, $v0 # n = numero lido	
	
	blt $t1, $zero, fim_loop_inserir #sai do loop se o numero lido < 0
	
	div $t1, $t2
	mfhi $t3 # i = n%16
	 
	mul $t3, $t3, 4 # Como cada posi��o do vetor tem 4 bytes, multiplica-se a posi��o por 4
	add $t3, $t7, $t3
	lw $t4, 0($t3) # tabela[i]
		
	li $v0, 9 #C�digo para alocar mem�ria
	li $a0, 12
	syscall
	
	lw $t5, 4($t4) # pant = tabela[i]->ant
	sw $v0, 4($t4) # tabela[i]->ant = node
	sw $v0, 8($t5) # pant->prox = node
	sw $t5, 4($v0) # node->ant = pant
	sw $t4, 8($v0) # node->prox = tabela[i]
	sw $t1, 0($v0) # node->val = n
	
	j loop_inserir
	
fim_loop_inserir:
	lw $ra, 0($sp)
	lw $a0, 4($sp)
	addi $sp, $sp, 4
	
	jr $ra

#Parametro $a0 - Tabela hash
remover_hash:
	addi $sp, $sp, -4
	sw $a0, 4($sp)
	sw $ra, 0($sp)
	
	move $t7, $a0
	li $t1, 16 #tamanho da hash
	
loop_remover:
	li $v0, 4 #C�digo para imprimir String
	la $a0, str_remover
	syscall

	li $v0, 5 #C�digo para leitura de inteiro 
	syscall
	
	move $t2, $v0
	blt $t2, $zero, fim_loop_remover
	
	div $t2, $t1
	mfhi $t3 #recupera o resto da divis�o
	
	mul $t4, $t3, 4
	add $t4, $t7, $t4
	lw $t4, 0($t4) #prem = tabela[i]
	lw $t4, 8($t4) #prem = prem->prox, primeira posi��o v�lida da tabela
	
loop_busca_remover:
	lw $t5, 0($t4) #val = prem->val
	blt $t5, $zero, fim_loop_busca_remover # Se val < 0 sai do loop
	beq $t2, $t5, remover_node #Se val == chave, remove o n� da lista
	
	lw $t4, 8($t4) #prem = prem->prox
	j loop_busca_remover
	
remover_node:
	lw $t3, 4($t4) #pant = prem->ant
	lw $t4, 8($t4) #prem = prem->prox
	
	sw $t4, 8($t3) #pant->prox = prem
	sw $t3, 4($t4) #prem->ant = pant
	
fim_loop_busca_remover:
	j loop_remover

fim_loop_remover:		
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	
	jr $ra
	
busca_hash:
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)
	
	move $t7, $a0 # tabela hash
	
	li $t2, 16 #tam = tamanho da hash
loop_busca:
	li $v0, 4 #C�digo para imprimir String
	la $a0, str_busca
	syscall
	
	li $v0, 5 #C�digo para ler inteiro
	syscall
	move $t1, $v0 #n = numero lido 	
	
	blt $t1, $zero, fim_loop_busca #Se o n < 0 sai do loop
	
	div $t1, $t2
	mfhi $t3 #pos = n % tam
	
	mul $t3, $t3, 4
	add $t3, $t3, $t7
	lw $t3, 0($t3) #cabeca = tabela[pos] 
	lw $t4, 8($t3) #pbusca = cabeca->prox, vai para a primeira pos valida da lista ligada
	
loop_busca_lista:
	lw $t5, 0($t4) #val = pbusca->val
	
	blt $t5, $zero, fim_loop_busca_lista_erro # Se val < 0, chegou no n� cabe�a e portanto n�o encontrou a chave
	beq $t5, $t1, fim_loop_busca_lista #Se val == chave, encontrou a chave na tabela
	
	lw $t4, 8($t4) #pbusca = pbusca->prox
	
	j loop_busca_lista
	
fim_loop_busca_lista_erro:
	li $v0, 4 #C�digo para imprimir string
	la $a0, str_chave
	syscall
	
	li $v0, 1 #C�digo para imprimir inteiro
	move $a0, $t1
	syscall
	
	li $v0, 4 #C�digo para imprimir string
	la $a0, str_busca_erro
	syscall
	j fim_busca_impressao
	
fim_loop_busca_lista:
	li $v0, 4 #C�digo para imprimir string
	la $a0, str_chave
	syscall
	
	li $v0, 1 #C�digo para imprimir inteiro
	move $a0, $t1
	syscall
	
	li $v0, 4 #C�digo para imprimir string
	la $a0, str_busca_encontrou
	syscall
	
fim_busca_impressao:
	j loop_busca
	
fim_loop_busca:
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra	

	
		
	
