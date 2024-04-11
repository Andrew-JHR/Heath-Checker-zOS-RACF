/*-------- REXX ------------*/
/* Updated from REDUREXX to list all users  aj 20080509 */
/* Updated for ROAUDIT                 timwang 20180907 */

Do forever
  'Readto  onelin'
   If Rc >< 0 Then leave
                                       /*------------------------------*/
                                       /* processing USER=             */
                                       /*------------------------------*/
    Parse var onelin 'USER=' user 'NAME=' name 'OWNER=' owner ,
              'CREATED=' created ' ' onelin
                                       /*------------------------------*/
                                       /* processing DEFGRP            */
                                       /*------------------------------*/
    Parse var onelin 'DEFAULT-GROUP=' defgrp 'PASSDATE=' pasdat ,
              'PASS-INTERVAL=' pasint . ' ' .
                                       /*------------------------------*/
                                       /* processing LAST-ACCESS       */
                                       /*------------------------------*/
    Parse var onelin 'LAST-ACCESS=' lasacc .
    lasacc = Left(lasacc,6)
    If lasacc = 'UNKNOW' Then lasacc = '00.000'
/* modified by Gerd Kolberger   27 Feb 2002 (02058)   13:03:08         */

                                       /*------------------------------*/
                                       /* processing USER Inst. data   */
                                       /*------------------------------*/
    Parse var onelin 'INSTALLATION-DATA=' inst_data1 ' ' inst_data2' ' .
    inst_data = Strip(inst_data1) || Strip(inst_data2)
/* modified by Gerd Kolberger   2 Sep 2004 (04246)   13:10:55          */



                                       /*------------------------------*/
                                       /* processing USER ATTRIBUTE*/
                                       /*------------------------------*/
    Parse var onelin 'ATTRIBUTES=' temp ' REVOKE' .
    uattri = ''
    If Pos('AUDITOR',temp)    > 0 Then uattri = uattri || 'A'
    Else uattri = uattri || '-'
    If Pos('ROAUDIT',temp)    > 0 Then uattri = uattri || 'R'
    Else uattri = uattri || '-'
    If Pos('SPECIAL',temp)    > 0 Then uattri = uattri || 'S'
    Else uattri = uattri || '-'
    If Pos('OPERATIONS',temp) > 0 Then uattri = uattri || 'O'
    Else uattri = uattri || '-'


/*---------------------------------------------------------------------*/
/* OMVS segment processing                                             */
/*---------------------------------------------------------------------*/
                                       /*      process OMVS    SEGMENT */
                                       /*------------------------------*/
    Parse var onelin 'OMVS INFORMATION'  onelin
    Parse var onelin 'UID= ' uid  ' '
    If strip(uid) = '0000000000' then uattri = uattri || '0'
    Else uattri = uattri || '-'
                                       /*------------------------------*/
                                       /*      process results         */
                                       /*------------------------------*/
    out = ' ',
      || Left(user         ,09),
      || Left(name         ,29),
      || Left(' '          ,01),
      || Left(uattri       ,07),
      || ''
                                       /*------------------------------*/
                                       /* return the result to the pipe*/
                                       /*------------------------------*/
   If Length(Strip(user)) = 0 Then
      Return
   Else
     'OUTPUT' out
  End
Return

