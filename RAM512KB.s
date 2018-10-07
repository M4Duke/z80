		; Extended RAM tester for Amstrad CPC expansions
		; To assemble use RASM assembler
		; Duke - 2018
		
		org	0x8000
		nolist
		
km_read_char	equ	0xBB09
km_wait_key		equ	0xBB18
txt_output		equ 0xBB5A
txt_set_column	equ 0xBB6F
txt_set_row		equ 0xBB72
txt_set_cursor	equ	0xBB75
txt_get_cursor	equ	0xBB78
txt_cur_on		equ	0xBB81
scr_reset		equ	0xBC0E
scr_set_ink		equ	0xBC32
scr_set_border	equ	0xBC38
scr_set_base	equ 0xBC08
kl_u_rom_enable	equ 0xB900
kl_u_rom_disable equ 0xB903
kl_rom_restore	equ 0xB90C
mc_wait_flyback	equ	0xBD19
kl_rom_select	equ 0xB90F

		ld a,2			
		call	scr_reset		; set mode 2
		xor a
		ld b,a
		call	scr_set_border
		xor a
		ld b,0
		ld c,0
		call	scr_set_ink
		ld a,1
		ld b,26
		ld c,26
		call	scr_set_ink

main:		
		ld	a,20
		call txt_set_column
		ld	hl,txt_title
		call wrt

		ld	hl,txt_test1
		call wrt
		;jp stage3
		
		; regular banking mode mem test
		
		ld	d,0xC4
		ld	hl,0x4000
		
		ld	bc,0x7FC0
		out (c),c
		ld	(hl),0xCC			; main ram check byte
		ld	e,0					; counter for amount of valid blocks
		ld	d,0xC4				; start page 0, bank 0
pb_ram_loop:
		
		call set_txt_pos
		
		call disp_ram_page_bank
		out (c),d				; switch in new bank

		; check all even and odd bits
		
		ld	a,0xAA
		ld	hl,0x4000
		call checkbank
		jr	nz, pb_ram_read_not_ok
		ld	a,0x55
		ld	hl,0x4000
		call checkbank
		jr	z, pb_ram_read_ok
pb_ram_read_not_ok:
		push hl
		ld	hl,txt_fail
		call wrt
		pop	hl
		jr	pb_next_bank
		
pb_ram_read_ok:
		ld	a,0x55
		call back_check_pagebank		; quick check to see if there was a duplicate bank
		cp	0xC4
		jr	z, pb_ram_read_ok1
		push hl
		ld	hl,txt_fail_conflict
		call wrt
		call disp_ram_page_bank
		pop	hl
		jr	pb_next_bank
pb_ram_read_ok1:
		out	(c),c				; back to base memory
		ld	a,(hl)				; check no writethrough occurred.
		cp	0xCC
		jr	z, pb_ram_bank_ok
		push hl
		ld	hl,txt_fail_write
		call wrt
		pop	hl
		ld	(hl),0xCC
		jr	pb_next_bank
pb_ram_bank_ok:		
		push hl
		ld	hl,txt_ok
		call wrt
		pop	hl
		inc	e
pb_next_bank:		
		ld	a,0b11				
		and	d					; keep bank
		cp 3
		jr z, pb_next_page
		inc	d					; increase bank
		jr pb_ram_loop
pb_next_page:
		ld	a,0b111000			; keep page
		and d
		cp 0b111000
		jr z, done512
		ld a,0b1000
		add d					; increase page
		and 0b11111100			; reset bank to 0
		ld d,a
		jp pb_ram_loop

done512:
		
		; display amount of "ok" banks found
		ld	l,e
		ld	h,0
		; multiply with 16
		add	hl,hl
		add	hl,hl
		add	hl,hl
		add	hl,hl
		call crlf
		call crlf
		call disp_dec16
		ld	hl,txt_mem
		call wrt
		call crlf
		ld	hl,txt_anykey
		call wrt
		call km_wait_key
stage2:		
		; use 0x4000 for screen
		ld	bc,0x7FC0
		out (c),c
		ld hl,0x4000
		ld de,0x4001
		ld bc,0x3fff
		ld (hl),0
		ldir
		
		ld a,0x40
		call scr_set_base
		ld a,20
		call txt_set_column
		ld a,1
		call txt_set_row
		ld	hl,txt_title
		call wrt
		ld	hl,txt_test2
		call wrt
		call crlf
		call crlf
		
		; C1 mode test 
		; make sure upperrom is not mapped
		call kl_u_rom_disable
		
		ld	hl,0xC000
		
		ld	bc,0x7FC0
		out (c),c
		ld	(hl),0xCC			; main ram check byte
		ld	e,0				; counter for amount of valid blocks
		ld	d,0xC1			; start page 0
p_ram_loop:
		
		call crlf
		
		call disp_ram_page
		out (c),d				; switch in new page

		; check all even and odd bits
		
		ld a,0xAA
		ld hl,0xC000
		call checkbank
		jr nz, p_ram_read_not_ok

		ld a,0x55
		ld hl,0xC000
		call checkbank
		jr	z, p_ram_read_ok
p_ram_read_not_ok:
	
		push hl
		ld	hl,txt_fail
		call wrt
		pop	hl
		jr	p_next_page
		
p_ram_read_ok:
		ld	a,0x55
		call back_check_page		; quick check to see if there was a duplicate page
		cp	0xC1
		jr	z, p_ram_read_ok1
		push hl
		ld	hl,txt_fail_conflict
		call wrt
		call disp_ram_page
		pop	hl
		jr	p_next_page
p_ram_read_ok1:
		out	(c),c				; back to base memory
		ld	a,(hl)				; check no writethrough occurred.
		cp	0xCC
		jr	z, p_ram_page_ok
		push hl
		ld	hl,txt_fail_write
		call wrt
		pop	hl
		ld	(hl),0xCC
		jr	p_next_page
p_ram_page_ok:		
		push hl
		ld	hl,txt_ok
		call wrt
		pop	hl
		inc	e
p_next_page:
		ld	a,0b111000			; keep page
		and d
		cp  0b111000
		jr	z, donep512
		ld	a,0b1000
		add	d					; increase page
		ld	d,a
		jp	p_ram_loop
		
donep512:
		
		; display amount of "ok" pages found
		ld	l,e
		ld	h,0
		
		call crlf
		call crlf
		call disp_dec16
		ld	hl,txt_mem1
		call wrt
		call crlf
		ld	hl,txt_anykey
		call wrt
		call km_wait_key
stage3:
		; C3 mode test 
		
		
		; use 0x4000 for screen
		ld	bc,0x7FC0
		out (c),c
		ld hl,0x4000
		ld de,0x4001
		ld bc,0x3fff
		ld (hl),0
		ldir
		ld hl,0xC000
		ld de,0xC001
		ld bc,0x3fff
		ld (hl),0
		ldir

		ld a,0x40
		call scr_set_base
		ld a,20
		call txt_set_column
		ld a,1
		call txt_set_row
		ld	hl,txt_title
		call wrt
		ld	hl,txt_test3
		call wrt
		call crlf
		call crlf
		ld	bc,0x7FC0
		out (c),c
		
		ld	hl,0xC000
		ld	(hl),0xCC			; main ram check byte
		ld	e,0					; counter for amount of valid blocks
		ld	d,0xC3				; start page 0
		
c3_ram_loop:
		
		call crlf
		call disp_ram_page
		out (c),d				; switch in new page

		; check all even and odd bits
		
		
		ld a,0xAA
		ld hl,0xC000
		call checkbank
		
		jr nz, c3_ram_read_not_ok
		ld a,0x55
		ld hl,0xC000
		call checkbank
		
		jr	z, c3_ram_read_ok
c3_ram_read_not_ok:
	
		push hl
		out (c),c
		ld	hl,txt_fail
		call wrt
		pop	hl
		jp	c3_next_page
		
c3_ram_read_ok:
		ld	a,0x55
		call c3_back_check_page			; quick check to see if there was a duplicate page
		cp	0xC3
		jr	z, c3_ram_read_ok1
		push hl
		out (c),c
		ld	hl,txt_fail_conflict
		call wrt
		call disp_ram_page
		pop	hl
		jr	c3_next_page
c3_ram_read_ok1:
		ld	a,(0x4000)			; this is base memory 0xC000 in non C3 mode
		cp	0xCC
		jr	z, c3_base_bank3_ok
		out	(c),c				; back to base memory
		push hl
		ld	hl,txt_fail_c3_bank
		call wrt
		pop	hl
	
		
c3_base_bank3_ok:
		out	(c),c				; back to base memory
		ld	a,(hl)				; check no writethrough occurred to base mem 0xC000.
		cp	0xCC
		jr	z, c3_ram_page_ok
		push hl
		ld	hl,txt_fail_write
		call wrt
		pop	hl
		ld	(hl),0xCC				; make sure it is 0xCC now, for next page
		jr	c3_next_page
c3_ram_page_ok:
		di
		out (c),d				; re-enter C3 mode with whatever page
		ld bc,0xDF00
		out (c),c				; select upper rom 0
		ld bc,0x7F86			; enable upper rom 
		out (c),c
		ld a,(0x4000)			; again this is base mem 0xC000 (this value should still be 0xCC) if remapped / shadowed
		ld e,a				; check val later
		ld a,(0xC000)			; here we should read first byte of ROM 0 (basic) which is 0x80
		out (c),c
		ld bc,0x7F8E			; disable upper rom, C3 mode now has priority again at 0xC000
		out (c),c
		
		ld bc,0x7FC0
		out (c),c				; no extended mem mode
		ei
		cp 0x80				; ROM value
		jr z, c3_rom_map_ok
		push hl
		ld	hl,txt_fail_rom
		call wrt
		pop	hl
		jr	c3_next_page
c3_rom_map_ok:
		ld a,e				; now check if base mem remapped to 0x4000 is valid
		cp 0xCC
		jr z, c3_rom_map_ok2
		push hl
		ld	hl,txt_fail_rom2	; this could be that ROM is mapped at 0x4000 too or base mem was not mapped
		call wrt
		pop	hl
		jr	c3_next_page
c3_rom_map_ok2:
		
		push hl
		ld	hl,txt_ok
		call wrt
		pop	hl
		
c3_next_page:
		ld	a,0b111000			; keep page
		and d
		cp  0b111000
		jr	z, done_c3_512
		ld	a,0b1000
		add	d					; increase page
		ld	d,a
		jp	c3_ram_loop
		
done_c3_512:
		
		; the end
endl:
		jr		endl
		
		; d = 11ppp1bb
disp_ram_page_bank:
		push hl
		ld hl, txt_page
		call wrt
		ld	a,d
		sra	a
		sra	a
		sra	a
		and	0b111
		call disp_hex
		
		ld hl, txt_bank
		call wrt
		ld	a,d
		and	0b11
		call disp_hex
		
		pop	hl
		ret
		
		; d = 11ppp1bb
disp_ram_page:
		push hl
		ld hl, txt_page
		call wrt
		ld	a,d
		sra	a
		sra	a
		sra	a
		and	0b111
		call disp_hex
		ld hl, txt_bank
		call wrt
		ld	a,3
		call disp_hex
		pop	hl
		ret		
		
		; back test page
		; loop backwards through pages, to ensure no other page was affected (duplicate)
		; a = value to check 
		; d = current page/bank
		; hl = memory address (0xC000)
		; return a=C1 is pass
back_check_page:
		push de
		ld	(bcp_val+1),a
		
bcp_loop:
		ld	a,d
		cp	0xC1
		jr z, bcp_done
	
		ld	a,0b111000
		and	d
		cp	0
		jr	z, bcp_next
		ld	a,d
		sub	0b1000		; decrease page
		ld	d,a
bcp_next:
		out	(c),d
		ld	a,(hl)
bcp_val:
		cp	0x55
		jr	nz,bcp_loop
bcp_done:
		pop	de
		out	(c),d		; set back to current page
		ld	(hl),0
		ret
		
		
c3_back_check_page:
		push de
		ld	(c3_bcp_val+1),a
		
c3_bcp_loop:
		ld	a,d
		cp	0xC3
		jr z, c3_bcp_done
	
		ld	a,0b111000
		and	d
		cp	0
		jr	z, c3_bcp_next
		ld	a,d
		sub	0b1000		; decrease page
		ld	d,a
c3_bcp_next:
		out	(c),d
		ld	a,(hl)
c3_bcp_val:
		cp	0x55
		jr	nz,c3_bcp_loop
c3_bcp_done:
		pop	de
		out	(c),d		; set back to current page
		ld	(hl),0
		ret
		
		; back test page&bank
		; loop backwards through pages and banks, to ensure no other bank was affected (duplicate)
		; a = value to check 
		; d = current page/bank
		; hl = memory address (0x4000)
		; return a=C4 is pass
back_check_pagebank:
		push de
		ld	(bcpb_val+1),a
		
bcpb_loop:
		ld	a,d
		cp	0xC4
		jr z, bcpb_done
		and	0b11
		cp	0
		jr	z,bcpb_bank_is0
		dec	d			; decrease bank num
		jr	bcpb_next
bcpb_bank_is0:
		ld	a,0b111000
		and	d
		cp	0
		jr	z, bcpb_next
		ld	a,d
		sub	0b1000		; decrease page
		or	0b11		; set bank 3
		ld	d,a
bcpb_next:
		out	(c),d
		ld	a,(hl)
bcpb_val:
		cp	0x55
		jr	nz,bcpb_loop
bcpb_done:
		pop	de
		out	(c),d		; set back to current page/bank
		ld	(hl),0
		ret

set_txt_pos:
		push hl
column:	ld	a,1
		push af
		call txt_set_column
		pop	af
		xor	41
		ld (column+1),a
		cp	40
		jr	nz, skip_row
row:	ld	a,5
		push af
		call txt_set_row
		pop	af
		
		inc a
		ld (row+1),a
skip_row:
		pop hl
		ret
disp_dec16:
		ld		bc,-10000
		call	n16_1
		cp		48
		jr		nz,not16_lead0
		ld		bc,-1000
		call	n16_1
		cp		48
		jr		nz,not16_lead1
		ld		bc,-100
		call	n16_1
		cp		48
		jr		nz,not16_lead2
		ld		bc,-10
		call	n16_1
		cp		48
		jr		nz, not16_lead3
		jr		not16_lead4

not16_lead0:
		call	txt_output
		ld		bc,-1000
		call	n16_1
not16_lead1:
		call	txt_output
		ld		bc,-100
		call	n16_1
not16_lead2:
		call	txt_output
		ld		c,-10
		call	n16_1
not16_lead3:
		call	txt_output
not16_lead4:
		ld		c,b
		call	n16_1
		call	txt_output
		ret
n16_1:
		ld		a,'0'-1
n16_2:
		inc		a
		add		hl,bc
		jr		c,n16_2
		sbc		hl,bc
		ret			
		
wrt:
		ld	a,(hl)
		or	a
		ret	z
		call txt_output
		inc	hl
		jr	wrt
			

		; a = input val
disp_hex:	
		push af
		push bc
		ld	b,a
		srl	a
		srl	a
		srl	a
		srl	a
		add	0x90
		daa
		adc	0x40
		daa
		call txt_output
		ld	a,b
		and	0x0f
		add	0x90
		daa
		adc	0x40
		daa
		call txt_output
		pop	bc
		pop	af
		ret

crlf:	push af
		ld a,10
		call txt_output
		ld a,13
		call txt_output
		pop af
		ret

		; a = fill value
		; hl = memory addr
checkbank:
		push hl
		push de
		push bc
		; fill bank
		push hl
		ld  d,h
		ld  e,l
		inc de
		ld	bc,0x3FFF
		ld	(hl),a
		ldir
		pop hl
		ld	bc,0x4000
comp_loop:
		cpi
		jr	nz, mismatch
		jp	pe, comp_loop
		
mismatch:		
		pop	bc
		pop	de
		pop	hl
		ret		
txt_title:
		db "Extended ram tester v1.0.1 - Duke 2018",10,13,0
txt_test1:
		db "Regular mode test",0
txt_test2:
		db "C1 mode test",0

txt_test3:
		db "C3 mode test",0

txt_page:
		db "Page ",0
txt_bank:
		db ",Bank ",0
txt_ok:
		db ", Ok.",0
txt_fail:
		db ", Fail.",0
txt_fail_conflict:
		db "-dup ",0
txt_fail_write:
		db "-write through!",0
txt_fail_c3_bank:
		db "-bank 3 no base ram remap!",0
txt_fail_rom:
		db "-rom not mapped 0xC000!",0
txt_fail_rom2:
		db "-rom remapped 0x4000!",0
txt_mem:
		db "KB of valid extended memory found!",10,13,0
txt_mem1:
		db " valid pages with bank 3 mapped to 0xC000 found!",10,13,0		
txt_anykey:
		db "Press any key to continue test.",0
