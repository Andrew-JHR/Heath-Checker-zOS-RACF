 /* rexx */                                                             00010000
 /* xmit the privilege id list to vm   andrewj 2008 apr 10 */           00020000
 /* use the TSO user id as the highest qualifier instead of 'SYS1'      00020100
    set the 2nd level qualifier as HCTOOL                               00020200
    also xmit the file: SYS1.HCTOOL.OSRS4ID                             00020300
                                       andrewj 2008 apr 21 */           00020400
 /* check return code for xmit and put warning messages                 00020500
    replace 'SYS1' with the userid for ???????.HCTOOL.OSRS4ID           00020601
                                       andrewj 2008 apr 22 */           00020701
 /* remove the deletion of HCTOOL.PRIVILID                              00020802
                                       andrewj 2008 May 09 */           00021002
 arg  arg1                                                              00022002
 dsn = sysvar(sysuid) || '.HCTOOL.PRIVILID'                             00030000
 "alloc fi(osridxmt) dsn('"dsn"') dsorg(ps) lrecl(8) blk(8000)" ||,     00040000
       " recfm(f,b) dsorg(ps) space(15,15) new "                        00050000
                                                                        00060000
 do forever   /* loop for all recs of input file */                     00070000
  "execio 1 diskr privilid"                                             00080000
      if rc \= 0  then                                                  00090000
        do                                                              00100000
         if rc =2 then leave                                            00110000
         else                                                           00120000
          do                                                            00130000
           say execname '"EXECIO DISKR" Exit=' rc                       00140000
          end                                                           00150000
        end                                                             00160000
   pull rec                                                             00170000
   queue  substr(rec,1,8)                                               00180000
   "execio 1 diskw osridxmt"                                            00190000
 end /* end of do forever */                                            00200000
                                                                        00210000
 "execio 0 diskr privilid (finis"                                       00220000
 "execio 0 diskw osridxmt (finis"                                       00230000
                                                                        00240000
 "xmit "arg1" dsn('"dsn"') "                                            00250000
 if rc = 0 then                                                         00270000
   say dsn  'successfully transmitted! '                                00270100
 else                                                                   00270200
   say dsn  'failed to be transmitted! '                                00270300
                                                                        00271000
 "free fi(osridxmt)"    /* deallocate file */                           00280000
                                                                        00290000
 dsn = sysvar(sysuid) || '.HCTOOL.OSRS4ID'                              00302001
 "xmit "arg1" dsn('"dsn"') "                                            00302100
 if rc = 0 then                                                         00302200
   say dsn  'successfully transmitted! '                                00302300
 else                                                                   00302400
   say dsn  'failed to be transmitted! '                                00302500
                                                                        00303000
  exit(0)                                                               00310000
                                                                        00320000
