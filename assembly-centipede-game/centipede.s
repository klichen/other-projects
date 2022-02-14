#####################################################################
# CSC258H Winter 2021 Assembly Final Project
# University of Toronto, St. George
#
# Student: Kevin Li Chen, 1006311901
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# -Milestone 1, 2, 3
#
# Which approved additional features have been implemented?
# None
#
# Any additional information that the TA needs to know:
# Max 5 darts, to make it a bit more challenging
# 's' key can be used to restart the game at any time
# the delay when a centipede or flea dies is intended. I thought of it like animating their death so the blaster player knows that they killed it. 
#####################################################################
.data
	bgColor: .word 0x000000
	mushroomColor: .word 0xd8ccc0
	fleaColor: .word 0x00FFFF
	blasterColor: .word 0x8A2BE2
	laserColor: .word 0xFFD700
	centipedeColor: .word 0x7CFC00
	centipedeHeadColor: .word 0xFF4500
	gameOverColor: .word 0xDC143C
	
	displayAddress:	.word 0x10008000
	blasterLocation: .word 1008
	dartX: .word 1, 1, 1, 1, 1
	dartY: .word 0, 0, 0, 0, 0
	
	centipedeX: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	centipedeY: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	centipedeDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	
	fleaX: .word 0
	fleaY: .word 0
.text 

init_blaster:
	la $t0, blasterLocation	# load the address of blasterlocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	lw $t3, blasterColor	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	li $s3, 3		# centipede lives
	
	

mushrooms:
    lw $t0, displayAddress  # $t0 stores the base address for display
    lw $t3, mushroomColor  
    addi $t5, $zero, 4
    addi $a3, $zero, 20
    mushroom_loop:
        jal get_random_mushroom_loc
        sll $t2, $a0, 2
        add $t6, $t0, $t2
        sw $t3, 0($t6) # paint random unit in $t6 as a mushroom
        addi $a3, $a3, -1 
        bne $a3, $zero, mushroom_loop

init_flea:
	li $s4, 0	# flea spawns when it is 0

game_loop:
	jal reset_centipede
	jal update_centipede
	jal check_keystroke
	
	addi $a2, $zero, 5
	la $a0, dartX
	la $a1, dartY
		laser_fired:
			
			lw $s1, 0($a0)
			lw $s0, 0($a1)
				
			sll $t4, $s0, 5				# idx = dart.y * 32
			add $t4, $t4, $s1		# idx = (dart.y * 32) + x
			sll $t4, $t4, 2				# idx = (dart.y * 32 + x) * 4
			add $t4, $t4, $gp
		
			lw $t5, laserColor
			lw $t6, bgColor
		
			sw $t6, 0($t4)		#paint previous black first
			beqz $s0, laser_done
	
			addi $s0, $s0, -1
	
			sll $t4, $s0, 5				# idx = dart.y * 32
			add $t4, $t4, $s1			# idx = (dart.y * 32) + x
			sll $t4, $t4, 2				# idx = (dart.y * 32 + x) * 4
			add $t4, $t4, $gp
	
			
			
			lw $t0, 0($t4)		#color of this pixel
			lw $t1, mushroomColor
			
			beq $t0, $t1, mushroom_hit	# check if laser hit a mushroom
			
			lw $t1, centipedeColor
			lw $t2, centipedeHeadColor
			
			beq $t0, $t1, centipede_hit
			beq $t0, $t2, centipede_hit
			
			lw $t1, fleaColor
			beq $t0, $t1, flea_hit
				
			sw $t5, 0($t4)
			sw $s1, 0($a0)
			sw $s0, 0($a1)
			j next_laser
			mushroom_hit:
				lw $t1, bgColor
				sw $t1, 0($t4)
				j laser_done
				
			centipede_hit:
				lw $t1, bgColor
				sw $t1, 0($t4)
				
				addi $s3, $s3, -1
				
				j laser_done
			flea_hit:
				jal kill_flea
				
				j laser_done
			
			laser_done:
				addi $t0, $zero, 0
				sw $t0, 0($a0)
				sw $t0, 0($a1)
			next_laser:
				addi $a0, $a0, 4	 # increment $a0 by one, to point to the next element in the array
				addi $a1, $a1, 4
				addi $a2, $a2, -1	
				bne $a2, $zero, laser_fired
		laser_not_fired:
			# Do nothing
	bgtz $s3, skip_centi_dead
	
	jal reset_centipede
	jal kill_centipede	
	addi $s3, $s3, 3	

	skip_centi_dead:
	bgtz $s4, skip_flea
		jal spawn_flea
		
		skip_flea:
			jal update_flea
	beqz $v1, skip_restart
	jal kill_centipede
	jal clear_screen
	jal reset_blaster
	jal reset_laser
	j init_blaster
	
		skip_restart:
			# do nothing
	li $v0, 32				# Sleep op code
	li $a0, 50				# Sleep 1/20 second 
	syscall
	
	j game_loop	

Exit:
	li $v0, 10		# terminate the program gracefully
	syscall

clear_screen:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	draw_bg:
		lw $t0, displayAddress		# Location of current pixel data
		addi $t1, $t0, 4096			# Location of last pixel data. Hard-coded below.
								          # 32x32 = 1024 pixels x 4 bytes = 4096.
		lw $t2, bgColor			# Colour of the background
	
	draw_bg_loop:
		sw $t2, 0($t0)				# Store the colour
		addi $t0, $t0, 4			# Next pixel
		blt $t0, $t1, draw_bg_loop
		
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# function for flea implementation
spawn_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal get_random_flea_loc
	addi $t7, $zero, 32
	div $a0, $t7 
	mflo $s0	# y coor
	mfhi $s1	# x coor
	
	bgtz $s1, skip_add_to_x
		add_to_x:
			addi $s1, $s1, 1
	skip_add_to_x:
	la $t0, fleaX	# load x coor of flea
	sw $s1, 0($t0)
	
	la $t2, fleaY	# load y coor of flea
	sw $s0, 0($t2)
	
	sll $t4, $s0, 5				# idx = flea.y * 32
	add $t4, $t4, $s1		# idx = (flea.y * 32) + x
	sll $t4, $t4, 2				# idx = (flea.y * 32 + x) * 4
	add $t4, $t4, $gp
	
	li $s4, 1
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

update_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t8, fleaX 	# load the address of the array into $a0
	la $t9, fleaY 	# load the address of the array into $a1
	lw $t1, 0($t8)	# x coor
	lw $t2, 0($t9)	# y coor
	
	sll $t4, $t2, 5				# idx = flea.y * 32
	add $t4, $t4, $t1		# idx = (flea.y * 32) + x
	sll $t4, $t4, 2				# idx = (flea.y * 32 + x) * 4
	add $t4, $t4, $gp
		
	lw $t5, fleaColor
	lw $t6, bgColor
	lw $t7, mushroomColor
	
	lw $t0, 0($t4)
	beq $t0, $t7, skip_top_right
	sw $t6, 0($t4)		# paint previous flea pixel black
	
	skip_top_right:
	lw $t0, -4($t4)
	beq $t0, $t7, skip_top_left
	sw $t6, -4($t4)
	
	skip_top_left:
	lw $t0, 128($t4)
	beq $t0, $t7, skip_bot_right
	sw $t6, 128($t4)
	
	skip_bot_right:
	lw $t0, 124($t4)
	beq $t0, $t7, skip_bot_left
	sw $t6, 124($t4)
	
	skip_bot_left:
	addi $t3, $zero, 1
	beq $t1, $t3, move_right
	addi $t3, $zero, 31
	beq $t1, $t3, move_left
	
	jal get_random_flea_movement_x
	bgtz $a0, move_right
		move_left:
			addi $t1, $t1, -1
			j move_y
		move_right:
			addi $t1, $t1, 1
	
	move_y:
		addi $t3, $zero, 0
		beq $t2, $t3, move_down
		addi $t3, $zero, 30
		beq $t2, $t3, move_up
		
		jal get_random_flea_movement_y
		bgtz $a0, move_down
			move_up:
				addi $t2, $t2, -1
				j done_moving
			move_down:
				addi $t2, $t2, 1
	done_moving:
		sll $t4, $t2, 5				# idx = flea.y * 32
		add $t4, $t4, $t1		# idx = (flea.y * 32) + x
		sll $t4, $t4, 2				# idx = (flea.y * 32 + x) * 4
		add $t4, $t4, $gp
		
		lw $t7, bgColor
		lw $t0, 0($t4)
		
		bne $t0, $t7, skip_paint
		lw $t0, -4($t4)
		bne $t0, $t7, skip_paint
		lw $t0, 128($t4)
		bne $t0, $t7, skip_paint
		lw $t0, 124($t4)
		bne $t0, $t7, skip_paint
		
		sw $t5, 0($t4)		# paint 
		sw $t5, -4($t4)
		sw $t5, 128($t4)
		sw $t5, 124($t4)
		skip_paint:
			sw $t1, 0($t8)
			sw $t2, 0($t9)
			
	lw $t0, blasterColor
	lw $t1, 0($t4)
	beq $t0, $t1, game_over_loop
	lw $t1, -4($t4)
	beq $t0, $t1, game_over_loop
	lw $t1, 128($t4)
	beq $t0, $t1, game_over_loop
	lw $t1, 124($t4)
	beq $t0, $t1, game_over_loop
		
	lw $ra, 0($sp)	
	addi $sp, $sp, 4
	
	jr $ra

kill_flea:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t8, fleaX 	# load the address of the array into $a0
	la $t9, fleaY 	# load the address of the array into $a1
	lw $t1, 0($t8)	# x coor
	lw $t2, 0($t9)	# y coor
	
	sll $t4, $t2, 5				# idx = flea.y * 32
	add $t4, $t4, $t1		# idx = (flea.y * 32) + x
	sll $t4, $t4, 2				# idx = (flea.y * 32 + x) * 4
	add $t4, $t4, $gp
		
	lw $t5, bgColor
	
	sw $t5, 0($t4)		# paint 
	jal delay_flea_death
	
	sw $t5, -4($t4)
	jal delay_flea_death
	
	sw $t5, 128($t4)
	jal delay_flea_death
	
	sw $t5, 124($t4)
	jal delay_flea_death
	
	li $s4, 0
	
	lw $ra, 0($sp)	
	addi $sp, $sp, 4
	
	jr $ra
	

# function to update centipede
update_centipede:
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	addi $a3, $zero, 10	 # load a3 with the loop count (10)
	la $a0, centipedeX # load the address of the array into $a0
	la $a1, centipedeY # load the address of the array into $a1
	la $a2, centipedeDirection # load the address of the array into $a2
	
segment_loop:
	lw $t0, 0($a0)		# x coor
	lw $t1, 0($a1)		# y coor
	lw $t2, 0($a2)
	
	bgtz $t2, check_right
	beqz $t2, check_left
	
		check_right:
			addi $t3, $zero, 31
			beq $t0, $t3, turn_left		# Check borders
			
			lw $t3, mushroomColor
			lw $t7, blasterColor
			
			addi $t0, $t0, 1
			sll $t4, $t1, 5				# idx = centipede.y * 32
			add $t4, $t4, $t0			# idx = (centipede.y * 32) + x
			sll $t4, $t4, 2				# idx = (centipede.y * 32 + x) * 4
			add $t4, $t4, $gp
			
			lw $t5, 0($t4)
			beq $t5, $t3, turn_left		# Check mushroom
			
			sw $t0, 0($a0)
			j paint_centi
			
		check_left:
			addi $t3, $zero, 0
			beq $t0, $t3, turn_right	# Check border
			
			lw $t3, mushroomColor
			
			addi $t0, $t0, -1
			sll $t4, $t1, 5				# idx = centipede.y * 32
			add $t4, $t4, $t0			# idx = (centipede.y * 32) + x
			sll $t4, $t4, 2				# idx = (centipede.y * 32 + x) * 4
			add $t4, $t4, $gp
			
			lw $t5, 0($t4)
			beq $t5, $t3, turn_right	# Check mushroom
			
			sw $t0, 0($a0)
			j paint_centi
			
	turn_right:
		addi $t4, $t1, 1
		addi $t5, $zero, 32
		
		beq $t4, $t5, turn1
		
		sw $t4, 0($a1)
		
		turn1:
			addi $t4, $zero, 1
			sw $t4, 0($a2)
		j paint_centi
		
	turn_left:
		addi $t4, $t1, 1
		addi $t5, $zero, 32
		
		beq $t4, $t5, turn2
		
		sw $t4, 0($a1)
		
		turn2:
			addi $t4, $zero, 0
			sw $t4, 0($a2)
		j paint_centi
	
	paint_centi:
		jal paint_segment
	
	addi $a0, $a0, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a1, $a1, 4
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, segment_loop
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# helper function to paint the correct pixel
paint_segment:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, 0($a1)
	lw $t0, 0($a0)
	
	sll $t4, $t1, 5				# idx = centipede.y * 32
	add $t4, $t4, $t0			# idx = (centipede.y * 32) + x
	sll $t4, $t4, 2				# idx = (centipede.y * 32 + x) * 4
	add $t4, $t4, $gp
	
	lw $t7, blasterColor
	lw $t8, 0($t4)
	
	beq $t8, $t7, game_over_loop	# Check if hit blaster
	
	lw $t5, centipedeColor
	lw $t7, centipedeHeadColor
	addi $t8, $zero, 1
	bgt $a3, $t8, paint_body 
	beq $a3, $t8, paint_head
	
	paint_body:
		sw $t5, 0($t4)		# paint the body with green
		j paint_done
	
	paint_head:
		sw $t7, 0($t4)		# paint the head with orange
		j paint_done
	
	paint_done:
		#do next
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# clears centipede pixels
reset_centipede:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a3, $zero, 10	 # load a3 with the loop count (10)
	la $a0, centipedeX # load the address of the array into $a1
	la $a1, centipedeY # load the address of the array into $a1
	la $a2, centipedeDirection # load the address of the array into $a2

arr_loop2:	#iterate over the loops elements to draw each body in the centiped
	lw $t1, 0($a0)		 # load a word from the centipedeX array into $t1
	lw $t2, 0($a1)		 # load a word from the centipedeY  array into $t5
	#####
	
	sll $t0, $t2, 5				# idx = centipede.y * 32
	add $t0, $t0, $t1			# idx = (centipede.y * 32) + x
	sll $t0, $t0, 2				# idx = (centipede.y * 32 + x) * 4
	add $t0, $t0, $gp
	
	li $t4, 0x000000
	
	sw $t4, 0($t0)		# paint the body with red
	
	addi $a0, $a0, 4	 # increment $a0 by one, to point to the next element in the array
	addi $a1, $a1, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	
	bgtz $s3, skip_slow_down
	jal delay
	
	skip_slow_down:
	bne $a3, $zero, arr_loop2
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

kill_centipede:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a3, $zero, 10	 	# load a3 with the loop count (10)
	la $a0, centipedeX 		# load the address of the array into $a1
	la $a1, centipedeY 		# load the address of the array into $a1
	la $a2, centipedeDirection 	# load the address of the array into $a2
	addi $t1, $zero, 0		# fill x
	addi $t2, $zero, 0 		# fill y
	addi $t3, $zero, 1 		# fill direction
	
kill_loop:	#iterate over the loops elements to draw each body in the centiped
	
	sw $t1, 0($a0)
	sw $t2, 0($a1)
	sw $t3, 0($a2)
	
	addi $t1, $t1, 1
	
	addi $a0, $a0, 4	 # increment $a1 by one, to point to the next element in the array
	addi $a1, $a1, 4
	addi $a2, $a2, 4
	addi $a3, $a3, -1	 # decrement $a3 by 1
	bne $a3, $zero, kill_loop
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

reset_blaster:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, blasterLocation
	addi $t1, $zero, 1008
	sw $t1, 0($t0)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
reset_laser:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, dartX
	la $t1, dartY
	addi $a3, $zero, 5
		reset_loop:
			addi $t2, $zero, 0
			sw $t2, 0($t0)
			sw $t2, 0($t1)
			
			addi $t0, $t0, 4
			addi $t1, $t1, 4
			addi $a3, $a3, -1
			bne $a3, $zero, reset_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# function to detect any keystroke
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $v1, 0	# not restarted
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0	#default case
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x73, respond_to_s
	beq $t2, 0x78, respond_to_x
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, blasterLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	beq $t1, 992, skip_movement # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1	# move the bug one location to the right
skip_movement:
	sw $t1, 0($t0)		# save the bug location

	lw $t3, blasterColor	# $t3 stores the blaster colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the first (top-left) unit white.
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, blasterLocation	# load the address of buglocation from memory
	lw $t1, 0($t0)		# load the bug location itself in t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4,$t1, 2		# $t4 the bias of the old buglocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 1023, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1	# move the bug one location to the right
skip_movement2:
	sw $t1, 0($t0)		# save the bug location

	lw $t3, blasterColor	# $t3 stores the white colour code
	
	sll $t4,$t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the block with white
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $a0, dartX
	la $a1, dartY
	addi $a3, $zero, 5
	
	iterate_lasers:
		lw $t1, 0($a1)
		beqz $t1, shoot_laser
		addi $a0, $a0, 4
		addi $a1, $a1, 4
		addi $a3, $a3, -1
		bne $a3, $zero, iterate_lasers
		j skip_shoot
	
	shoot_laser:
		la $t0, blasterLocation
		lw $t7, 0($t0)
		addi $t1, $zero, 32
		div $t7, $t1 
		mflo $s0	# y coor
		mfhi $s1	# x coor
		addi $s0, $s0, -1
		
		sw $s1, 0($a0)
		sw $s0, 0($a1)
		
	skip_shoot:
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $v1, 1
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
delay:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $a2, 50000
	delay_func:
		addi $a2, $a2, -1
		bgtz $a2, delay_func
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

delay_flea_death:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $s2, 60000
	delay_func2:
		addi $s2, $s2, -1
		bgtz $s2, delay_func2
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

get_random_mushroom_loc:
	li $v0, 42         # Service 42, random int bounded
      	li $a0, 0          # Select random generator 0
     	li $a1, 959
     	syscall             # Generate random int (returns in $a0)
     	jr $ra
      
get_random_flea_loc:
	li $v0, 42
	li $a0, 0
	li $a1, 640
	syscall
	jr $ra
get_random_flea_movement_x:
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	jr $ra
get_random_flea_movement_y:
	li $v0, 42
	li $a0, 0
	li $a1, 3
	syscall
	jr $ra

game_over_loop:
	lw $t0, displayAddress
	addi $t0, $t0, 1304
	lw $t1, gameOverColor
	# draw G
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 524($t0)
	sw $t1, 396($t0)
	sw $t1, 268($t0)
	sw $t1, 264($t0)
	
	# draw A
	lw $t0, displayAddress
	addi $t0, $t0, 1324
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 512($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 268($t0)
	sw $t1, 140($t0)
	sw $t1, 396($t0)
	sw $t1, 524($t0)
	
	#draw M
	lw $t0, displayAddress
	addi $t0, $t0, 1344
	sw $t1, 0($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 132($t0)
	sw $t1, 264($t0)
	sw $t1, 140($t0)
	sw $t1, 16($t0)
	sw $t1, 144($t0)
	sw $t1, 272($t0)
	sw $t1, 400($t0)
	sw $t1, 528($t0)
	
	# draw E
	lw $t0, displayAddress
	addi $t0, $t0, 1368
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 524($t0)
	
	# draw O
	lw $t0, displayAddress
	addi $t0, $t0, 2200
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 396($t0)
	sw $t1, 268($t0)
	sw $t1, 140($t0)
	
	# draw V
	lw $t0, displayAddress
	addi $t0, $t0, 2220
	sw $t1, 0($t0)
	sw $t1, 12($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 396($t0)
	sw $t1, 268($t0)
	sw $t1, 140($t0)
	sw $t1, 388($t0)
	sw $t1, 392($t0)
	
	# draw E
	lw $t0, displayAddress
	addi $t0, $t0, 2240
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 524($t0)
	
	# draw R
	lw $t0, displayAddress
	addi $t0, $t0, 2260
	sw $t1, 0($t0)
	sw $t1, 524($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 140($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	
	#draw !
	lw $t0, displayAddress
	addi $t0, $t0, 2280
	sw $t1, 0($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	
	li $v0, 32 # sleep
	li $a0, 1000
	
	lw $t8, 0xffff0000				# Check MMIO location for keypress 
	beq $t8, 1, keyboard_input		# If we have input, jump to handler
	j keyboard_input_done			# Otherwise, jump till end

	keyboard_input:
		lw $t8, 0xffff0004				# Read Key value into t8
   		beq $t8, 0x73, key_restart # If `s`, restart the game from end screen
	j keyboard_input_done
	
	key_restart:
		jal kill_centipede
		jal clear_screen
		jal reset_blaster
		jal reset_laser
		j init_blaster
	
	keyboard_input_done:
	j game_over_loop
