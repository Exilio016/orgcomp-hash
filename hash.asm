.data
.align 0

str_inserir: .asciiz "\nDigite a chave a ser inserida, ou -1 para finalizar a inserção: "
str_remover: .asciiz "\nDigite a chave a ser removida, ou -1 para finalizar a remoção: "
str_busca: .asciiz "\nDigite a chave a ser buscada, ou -1 para finalizar a busca: "
str_menu: .asciiz "Menu: \n1 - Inserir na Hash \n2 - Remover da Hash \n3 - Buscar na Hash \n4 - Vizualizar Hash \n5 - Sair\n"
str_vizu1: .asciiz " - "
str_vizu2: .asciiz " ,"
str_end_line: .asciiz "\n"

.align 2
.text
.globl main
main:

	jal criar_tabela_hash
	move $s1, $v0
	
loop_main:
	li $v0, 4 #Código para imprimir string
	la $a0, str_menu
	syscall
	
	#Opções do menu
	li $t1, 1
	li $t2, 2
	li $t3, 3
	li $t4, 4
	li $t5, 5
	
	li $v0, 5
	syscall
	
	beq $v0, $t1, main_inserir
	beq $v0, $t2, main_remover
	beq $v0, $t3, main_busca
	beq $v0, $t4, main_visualizar
	beq $v0, $t5, main_sair
	
	j loop_main #Se digitou comando inválido, volta na leitura 

main_inserir:
	move $a0, $s1
	jal inserir_hash
	j loop_main

main_busca:
	move $a0, $s1
	jal busca_hash
	j loop_main
	
main_remover:
	move $a0, $s1
	jal remover_hash
	j loop_main

main_visualizar:
	move $a0, $s1
	jal vizualizar_hash
	j loop_main
	
main_sair:
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
	
	#Alocação de tabela[16]
	li $v0, 9 #serviço para alocação de bytes
	li $a0, 64 # 4 * 16 = 64
	syscall
	move $t1, $v0
	
	li $t2, 16 #i = 16, usado no loop
	move $t3, $v0 #usado para controlar a inserção no vetor	
loop_criar_tabela:
	 beq $zero, $t2, fim_loop_criar # while(i != 0)
	
	 li $v0, 9
	 li $a0, 12
	 syscall
	 
	 li $t5, -1 
	 sw $t5, 0($v0) # node->val = -1,  (-1) marca que é nó cabeça
	 sw $v0, 4($v0) # node->ant = node =>lista circular
	 sw $v0, 8($v0)	# node->prox = node => lista circular
	 
	 sw $v0, 0($t3)
	 addi $t3, $t3, 4 #avança uma posição no vetor(4 bytes)
	 addi $t2, $t2, -1 #i = i -1
	 
	 j loop_criar_tabela
	 
fim_loop_criar:	
	move $v0, $t1 # A função retorna tabela[16]
	
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
	li $v0, 4 #Código para imprimir String
	la $a0, str_inserir
	syscall
	
	li $v0, 5 #Código para ler inteiro
	syscall
	move $t1, $v0 # n = numero lido	
	
	blt $t1, $zero, fim_loop_inserir #sai do loop se o numero lido < 0
	
	div $t1, $t2
	mfhi $t3 # i = n%16
	 
	mul $t3, $t3, 4 # Como cada posição do vetor tem 4 bytes, multiplica-se a posição por 4
	add $t3, $t7, $t3
	lw $t4, 0($t3) # tabela[i]
		
	li $v0, 9 #Código para alocar memória
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
	addi $sp, $sp, 8
	
	jr $ra

#Parametro $a0 - Tabela hash
remover_hash:
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)
	
	move $t7, $a0
	li $t1, 16 #tamanho da hash
	
loop_remover:
	li $v0, 4 #Código para imprimir String
	la $a0, str_remover
	syscall

	li $v0, 5 #Código para leitura de inteiro 
	syscall
	
	move $t2, $v0
	blt $t2, $zero, fim_loop_remover
	
	div $t2, $t1
	mfhi $t3 #recupera o resto da divisão
	
	mul $t4, $t3, 4
	add $t4, $t7, $t4
	lw $t4, 0($t4) #prem = tabela[i]
	lw $t4, 8($t4) #prem = prem->prox, primeira posição válida da tabela
	
loop_busca_remover:
	lw $t5, 0($t4) #val = prem->val
	blt $t5, $zero, fim_loop_busca_remover # Se val < 0 sai do loop
	beq $t2, $t5, remover_node #Se val == chave, remove o nó da lista
	
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
	addi $sp, $sp, 8
	
	jr $ra
	
busca_hash:
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)
	
	move $t7, $a0 # tabela hash
	
	li $t2, 16 #tam = tamanho da hash
loop_busca:
	li $v0, 4 #Código para imprimir String
	la $a0, str_busca
	syscall
	
	li $v0, 5 #Código para ler inteiro
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
	
	blt $t5, $zero, fim_loop_busca_lista_erro # Se val < 0, chegou no nó cabeça e portanto não encontrou a chave
	beq $t5, $t1, fim_loop_busca_lista #Se val == chave, encontrou a chave na tabela
	
	lw $t4, 8($t4) #pbusca = pbusca->prox
	
	j loop_busca_lista
	
fim_loop_busca_lista_erro:
	li $v0, 1 #Código para imprimir inteiro
	li $a0, -1
	syscall
	
	j fim_busca_impressao
	
fim_loop_busca_lista:
	li $v0, 1 #Código para imprimir inteiro
	move $a0, $t1
	syscall

fim_busca_impressao:
	j loop_busca
	
fim_loop_busca:
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	
	jr $ra	
	
vizualizar_hash:
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)
	
	move $t7, $a0
	li $t1, 16 #Auxiliar na hora de percorrer o vetor tabela
	li $t0, 0 #pos = 0
	
loop_vizualizar:
	beq $t0, $t1, fim_loop_vizualizar
	
	lw $t2, 0($t7) #cabeca = tabela[pos]
	lw $t2, 8($t2) #cabeca = cabeca->prox
	lw $t3, 0($t2) #val = cabeca->val
	
	li $v0, 1 #Código para imprimir inteiro
	move $a0, $t0
	syscall
	
	li $v0, 4 #Código para imprimir string
	la $a0, str_vizu1
	syscall
	
loop_vizualizar_lista:
	blt $t3, $zero, fim_loop_vizualizar_lista
	
	li $v0, 1 #Código para imprimir inteiro
	move $a0, $t3
	syscall
	
	li $v0, 4 #Código para imprimir string
	la $a0, str_vizu2
	syscall
	
	lw $t2, 8($t2) #cabeca = cabeca->prox
	lw $t3, 0($t2) #val = cabeca->val
	
	j loop_vizualizar_lista
	
fim_loop_vizualizar_lista:
	addi $t0, $t0, 1 #pos = pos + 1
	addi $t7, $t7, 4 #Anda uma posição(4 bytes) no vetor tabela
	
	li $v0, 4 #Código para imprimir string
	la $a0, str_end_line
	syscall
	
	j loop_vizualizar

fim_loop_vizualizar:
	lw $a0, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	
	jr $ra		
	
