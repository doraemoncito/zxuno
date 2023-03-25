; mc.asm - multicore load any .ZX1 core on slot 9 or 45.
; File must exists in current directory.  It must be run while using a "root" mode ROM.
;
; Copyright (C) 2022 Antonio Villena
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, version 3.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.
;
; Compatible compilers:
;   SjAsmPlus, <https://github.com/z00m128/sjasmplus>

;               output  ZX1

        define  romtbl  $d000
        define  indexe  $e000
        define  active  $e040

        define  bitstr  active+1
        define  quietb  bitstr+1
        define  checkc  quietb+1
        define  keyiss  checkc+1
        define  timing  keyiss+1
        define  conten  timing+1
        define  divmap  conten+1
        define  nmidiv  divmap+1
        define  grapmo  nmidiv+1
        define  layout  grapmo+1
        define  joykey  layout+1
        define  joydb9  joykey+1
        define  split   joydb9+1
        define  outvid  split+1
        define  scanli  outvid+1
        define  freque  scanli+1
        define  cpuspd  freque+1
        define  copt    cpuspd+1
        define  cburst  copt+1

        define  cmbpnt  $e100
        define  cmbcor  $e1d0   ;lo: Y coord          hi: X coord
        define  items   $e1d2   ;lo: totales          hi: en pantalla
        define  offsel  $e1d4   ;lo: offset visible   hi: seleccionado
        define  empstr  $e1d6
        define  tmpbuf  $e200

                include zxuno.def
                include esxdos.def

                org     $8000
                jr      NoPrint
                db      'BP', 0, 0, 0, 0, 'ZX1 plugin - antoniovillena', 0
NoPrint         ld      (FileName+1), hl
                ld      bc, zxuno_port
                out     (c), 0
                inc     b
                in      f, (c)
                jp      p, Nonlock
                call    Print
                dz      'ROM not rooted'
                ret
Nonlock         wreg    flash_cs, 0     ; activamos spi, enviando un 0
                wreg    flash_spi, $9f  ; jedec id
                in      a, (c)
                in      a, (c)
                in      a, (c)
                in      a, (c)
                wreg    flash_cs, 1     ; desactivamos spi, enviando un 1
                sub     $18
                jr      z, Goodflsh
                ld      hl, $2f80
                ld      (Slot+1), hl
                inc     a
                inc     a
                jr      z, Goodflsh
                call    Print
                dz      'Incorrect flash IC'
                ret
Goodflsh        ld      a, scandbl_ctrl
                dec     b
                out     (c), a
                inc     b
                in      a, (c)
                and     $3f
                ld      (Normal+1), a
                or      $c0
                out     (c), a
                call    Init
                ld      bc, zxuno_port
                ld      a, scandbl_ctrl
                out     (c), a
                inc     b
Normal          ld      a, 0
                out     (c), a
                ld      a, 7            ;PLUGIN_OK|PLUGIN_RESTORE_SCREEN|PLUGIN_RESTORE_BUFFERS
                ret
Init            wreg    flash_cs, 1
                ld      de, indexe
                ld      hl, $0070
                ld      a, 1
                call    rdflsh
                xor     a
                esxdos  M_GETSETDRV     ; A = unidad actual
                jr      nc, SDCard
                call    Print
                dz      'SD card not inserted'
                ret
SDCard          ld      (Drive+1), a
                ld      b, FA_READ      ; B = modo de apertura
FileName        ld      hl, 0
                esxdos  F_OPEN
                ld      (Handle+1), a
                jr      nc, FileFound
                call    Print
                dz      'File not found'
                ret
FileFound       call    Print
                db      13, 'Writing SPI flash', 13
                dz      '[', 6, '      ]', 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8
                ld      ixl, $15
Slot            ld      de, $f7c0
                exx
Bucle           ld      a, 'o'
                exx
                push    de
                rst     $10
                pop     de
                exx
                ld      hl, $c000
                ld      bc, $4000
Handle          ld      a, 0
                esxdos  F_READ
                jr      nc, ReadOK
                call    Print
                dz      'Read Error'
                ret
ReadOK          ld      a, $40
                ld      hl, $c000
                exx
                call    wrflsh
                inc     de
                exx
                dec     ixl
                jr      nz, Bucle
                ld      bc, zxuno_port
                ld      hl, (Slot+1)
                ld      a, core_addr
                out     (c), a
                inc     a
                inc     b
                out     (c), h
                out     (c), l
                out     (c), 0
                dec     b
                out     (c), a
                inc     b
                out     (c), a
                include Print.inc
                include rdflsh.inc
                include wrflsh.inc
                include rst28.inc
