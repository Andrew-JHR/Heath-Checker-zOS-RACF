**********************************************************************
* List all LPA, APF and Linklist data set names that are in effect   *
* Andrew Jan 26/Mar/2008                                             *
* Also read in a sequential file: HC before doing the sorting        *
* Andrew Jan 31/Mar/2008                                             *
* Updated to add the checking of the authority field            M080408
* Andrew Jan 08/Apr/2008                                        M080408
* Updated to also process a group class member                  M080408
* Andrew Jan 28/Apr/2008                                        M080428
**********************************************************************
         PRINT NOGEN
*------------------------------------------------*
*
         PRINT OFF
         LCLA  &REG
.LOOP    ANOP                              GENERATE REGS.
R&REG    EQU   &REG
&REG     SETA  &REG+1
         AIF   (&REG LE 15).LOOP
         PRINT ON
*
*
*------------------------------------------------*
*
OSRHC    CSECT
OSRHC    AMODE 31
         USING *,R15              setup addressibility
         STM   R14,R12,12(R13)      USE R13 AS BASE AS WELL AS
         LR    R2,R13               REG-SAVE AREA
         STM   R14,R12,12(R13)    save parent's register
         LR    R2,R13             parent's save area pointer
         B     CMNTTAIL           skip over the remarks
*
CMNTHEAD EQU   *
         PRINT GEN                print out remarks
         DC    CL8'&SYSDATE'      compiling date
         DC    C' '
         DC    CL5'&SYSTIME'      compiling time
         DC    C'ANDREW JAN'      author
         CNOP  2,4                ensure half word boundary
         PRINT NOGEN              disable macro expansion
CMNTTAIL EQU   *

         BALR  R12,0
         BAL   R13,76(R12)

         DROP  R15                avoid compiling warning

SAVREG   DS    18F
         USING SAVREG,R13
         ST    R2,4(R13)
         ST    R13,8(R2)
*
*---MAINSTREAM------------------------------------*
*
*
        OPEN  (PRINT,OUTPUT,SORTIN,OUTPUT,GRPIN,INPUT)          M080428
        B      READ_GRP                                         M080428
GRPEND  EQU    *                                                M080428
        CLOSE (GRPIN,,SORTIN)      CLOSE FILES                  M080428
        BAL    R6,SORT_RTN         sort out those duplicate     M080428
        OPEN   (SORTOUT,INPUT,GRPCLASS,OUTPUT)                  M080428
        B      GIGO                                             M080428
SRTEND  EQU    *                                                M080428
        CLOSE (SORTOUT,,GRPCLASS)  CLOSE FILES                  M080428
*
        BAL    R6,OPEN_FILES        open the output file
*
        BAL    R6,GO_LPALIST        go process lpa list
        BAL    R6,GO_APFLIST        go process apf list
        BAL    R6,GO_LNKLIST        go process lnk list
        B      READ_HC              read other HC names
FINISH  EQU    *
        BAL    R6,CLOSE_SORTIN      process lnk list
        BAL    R6,SORT_RTN          sort out those duplicate dsns
*
        BAL    R6,CLOSE_FILES       close the output file
*
        B      RETURN               back
*
*-------------------------------------------------------*
*
GO_LPALIST  EQU   *

         L     R10,X'10'            get CVT addr
         L     R10,CVTSMEXT-CVTMAP(R10) addr of storage map extension
         L     R10,CVTEPLPS-CVTVSTGX(R10) start of eplpa

LPA_1    EQU   *
         USING LPAT,R10             set the addressibility
         L     R7,LPATCNT           total number of entries
LPA_2    EQU   *
         MVC   OUTAREA,BLANKS       clean output area
         XR    R2,R2                clean
         ICM   R2,B'0001',LPATDSLN  dsn name length
         BCTR  R2,0                 subtract for ED
MVCLPA   MVC   OUTAREA(0),LPATDSN   dsn name
         EX    R2,MVCLPA            do the move by specifying the len
         MVC   OUTAREA+41(6),=C'UPDATE'                         M080408
         PUT   SORTIN,OUTAREA       print it
         LA    R10,L'LPATENTRY(,R10) length to next apfe
         BCT   R7,LPA_2             loop till all are processed

LPA_99   EQU   *

         BR    R6

*
*--------------------------------------------------------*
*
GO_APFLIST  EQU   *

         L     R15,X'10'            get CVT addr
         TM    CVTDCB-CVTMAP(R15),CVTOSEXT  os extension present?
         BZ    STATIC_APF           no,branch
         TM    CVTOSLV1-CVTMAP(R15),CVTDYAPF is dynamic apf present?
         BZ    STATIC_APF           no,branch
         MVC   APAALEN,=AL4(4096)   assume 4k in length
         L     R2,APAALEN           load the length
         GETMAIN RU,LV=(R2)         get an answer area
         ST    R1,APAA@             save address

APF_1    EQU   *

         L     R4,APAA@             addr of save area
         CSVAPF  REQUEST=LIST,ANSAREA=(R4),ANSLEN=APAALEN,             *
               RETCODE=RETCODE,RSNCODE=RSNCODE
         CLC   RETCODE,=AL4(CSVAPFRC_OK)     success?
         BE    APF_3                yes, go on
* room size too small
         CLC   RETCODE,=AL4(CSVAPFRC_WARN)   warning?
         BNE   APF_2                no, check other reasons
         NC    RSNCODE,=AL4(CSVAPFRSNCODEMASK) clear high order bits
         CLC   RSNCODE,=AL4(CSVAPFRSNNOTALLDATARETURNED)  more data?
         BNE   APF_2                yes, check other reasons
         L     R3,APAALEN           get current size
         L     R2,APFHTLEN-APFHDR(R4) get required size
         ST    R2,APAALEN           save it
         FREEMAIN RU,A=(R4),LV=(R3) release old area
         GETMAIN RU,LV=(R2)         new area
         ST    R1,APAA@             save address
         B     APF_1                try again

APF_2    EQU   *
         MVC   OUTAREA,BLANKS     clear output area
         MVC   OUTAREA(34),=C'A Unexpected Error encountered !!!'
         PUT   PRINT,OUTAREA       print the warning
         B     APF_99

APF_3    EQU   *
         USING APFHDR,R4            get access to the header
         L     R7,APFH#REC          total number of entries
         A     R4,APFHOFF           locate the 1st entry
         DROP  R4
         USING APFE,R4              get access to the entry
APF_4    EQU   *
         MVC   OUTAREA,BLANKS       clean output area
**       MVC   OUTAREA(6),APFEVOLUME  volser
         XR    R2,R2                clean
         ICM   R2,B'0001',APFEDSLEN dsn name length
         BCTR  R2,0                 subtract for ED
MVCAPF   MVC   OUTAREA(0),APFEDSNAME  dsn name
         EX    R2,MVCAPF            do the move by specifying the len
         MVC   OUTAREA+41(6),=C'UPDATE'                         M080408
         PUT   SORTIN,OUTAREA       print it
         LH    R2,APFELEN           length to next apfe
         AR    R4,R2                get next apfe
         BCT   R7,APF_4             loop till all are processed

APF_99   EQU   *

         L     R2,APAALEN           get size
         L     R4,APAA@             get addr of area
         FREEMAIN RU,LV=(R2),A=(R4)
         BR    R6

STATIC_APF   EQU *
         MVC   OUTAREA,BLANKS     clear output area
         MVC   OUTAREA(33),=C'Static APF, not supported now !!!'
         PUT   PRINT,OUTAREA
         BR    R6
*
*--------------------------------------------------------*
*
GO_LNKLIST  EQU   *

         L     R2,=AL4(INITDLAA)    initial answer area size
         ST    R2,SIZEDLAA          save
         GETMAIN RU,LV=(R2)         get an answer area
         ST    R1,DLAA@             save address

LNK_1    EQU   *

         L     R4,DLAA@             addr of save area
         CSVDYNL REQUEST=LIST,ANSAREA=(R4),ANSLEN=SIZEDLAA,            *
               RETCODE=RETCODE,RSNCODE=RSNCODE,MF=(E,DYNLL)
         CLC   RETCODE,=AL4(CSVDYNLRC_WARN)  warning?
         BNE   LNK_2                no, requst ok or error
* room size too small
         LR    R3,R2                save current size
         L     R2,DLAAHTLEN-DLAAHDR(4)   get necessary size
         FREEMAIN RU,A=(R4),LV=(R3) release old area
         ST    R2,SIZEDLAA          save it
         GETMAIN RU,LV=(R2)         new area
         ST    R1,DLAA@             save address
         B     LNK_1                try again

LNK_2    EQU   *
         CLC   RETCODE,=AL4(CSVDYNLRC_OK)   success?
         BNE   LNK_99

         USING DLAAHDR,R4           addressibility
         L     R5,DLAAH#LS          how many dlaals entries
         LTR   R5,R5                zero?
         BZ    LNK_99               yes, branch
         L     R4,DLAAHFIRSTLS@     get 1st entry
         USING DLAALS,R4            dlaals dsect

LNK_3    EQU   *
         LH    R7,DLAALS#DS         get # of dlaads entries
         N     R7,CLEAR0TO15        clear 0 to 15 bits
         BZ    LNK_8                bottom of dlaals loop

         L     R8,DLAALSFIRSTDS@    get 1st dlaads

LNK_5    EQU   *
         MVC   OUTAREA,BLANKS       clean output area
         USING DLAADS,R8            dlaads dsect
**       TM    DLAADSFLAGS,DLAADSAPF apf ?
**       BNO   LNK_53                no, branch
**       MVC   OUTAREA(1),=C'A'      yes
**LNK_53   EQU   *
**       MVC   OUTAREA+2(6),DLAADSVOLID volser
         LH    R2,DLAADSNAMELEN     dsn name length
         BCTR  R2,0                 subtract for ED
MVCLNK   MVC   OUTAREA(0),DLAADSNAME  dsn name
         EX    R2,MVCLNK            do the move by specifying the len
         MVC   OUTAREA+41(6),=C'UPDATE'                         M080408
         PUT   SORTIN,OUTAREA       print it
         L     R8,DLAADSNEXT@       get next dlaads
         BCT   R7,LNK_5             inner loop

LNK_8    EQU   *
         L     R4,DLAALSNEXT@       get next dlaals
         BCT   R5,LNK_3             outer loop

LNK_99   EQU   *

         L     R2,SIZEDLAA          get size
         L     R4,DLAA@             get addr of area
         FREEMAIN RU,LV=(R2),A=(R4)

         BR    R6
*                                                               M080428
*--------------------------------------------------------*      M080428
*                                                               M080428
READ_GRP  EQU  *                                                M080428
         GET   GRPIN              read a record                 M080428
         LR    R4,R1              save the reg                  M080428
         CLC   0(2,R4),=C'/*'     comment line ?                M080428
         BE    READ_GRP           skip this line                M080428
         CLC   0(8,R4),=C'        '  blank?                     M080428
         BE    READ_GRP           skip this line                M080428
         PUT   SORTIN,0(R4)       copy this rec                 M080428
         B     READ_GRP           loop till all are read        M080428
*                                                               M080428
*--------------------------------------------------------*      M080428
*                                                               M080428
GIGO     EQU  *                                                 M080428
         GET   SORTOUT            read a record                 M080428
         LR    R4,R1              save the reg                  M080428
         PUT   GRPCLASS,0(R4)     copy this rec                 M080428
         B     GIGO               loop till all are read        M080428
*
*--------------------------------------------------------*
*
READ_HC   EQU  *
         GET   HCIN               read a record
         LR    R4,R1              save the reg
         CLC   0(2,R4),=C'/*'     comment line ?
         BE    READ_HC            skip this line
         CLC   0(8,R4),=C'        '  blank?
         BE    READ_HC            skip this line
         PUT   SORTIN,0(R4)       copy this rec
         B     READ_HC            loop till all are read
*
*--------------------------------------------------------*
*
SORT_RTN  EQU  *
         LA    R1,SORTPARM
         LINK  EP=SORT
         LTR   R15,R15
         BNZ   SORT_ERR
         BR    R6
SORT_ERR  EQU  *
         MVC   OUTAREA,BLANKS     clear output area
         MVC   OUTAREA(28),=C'## Sort Error encountered ##'
         PUT   PRINT,OUTAREA      print the error code
         BR    R6
*
*--------------------------------------------------------*
*
OPEN_FILES EQU  *
         OPEN  (SORTIN,OUTPUT,HCIN,INPUT)      remove print     M080428
         BR    R6
*
*--------------------------------------------------------*
*
CLOSE_SORTIN EQU  *
         CLOSE (HCIN,,SORTIN)      CLOSE FILES
         BR    R6
*
*--------------------------------------------------------*
*
CLOSE_FILES EQU  *
         CLOSE PRINT               CLOSE FILES
         BR    R6
*
*--------------------------------------------------------*
*
RETURN   EQU   *
         L     R13,4(R13)
         ST    R15,16(,R13)        save the return code
         LM    R14,R12,12(R13)     restore registers
         L     R14,12(,R13)        load return address
         BR    R14                 go back to caller
*
*--------------------------------------------------------*
*
         LTORG

DSNLEN   EQU   50*DLAADS_LEN    room for 50 data set's info
LSLEN    EQU   3*DLAALS_LEN     room for 3 lnklst sets' info
INITDLAA EQU   DLAAHDR_LEN+DSNLEN+LSLEN  initial ansarea size
DLAA@    DS    A                addr of answer area
SIZEDLAA DS    F                size of answer area

APAA@    DS    A                addr of answer area
APAALEN  DS    F                size of answer area
RETCODE  DS    F                return code
RSNCODE  DS    F                reason code

OUTAREA  DS    CL80
BLANKS   DS    0CL80
         DC    80C' '

       CNOP 0,4
SORTPARM DC    X'00'               extended parameter list
         DC    AL3(SORTCTL)        control statements
         DC    A(0)                no input procedure
         DC    A(0)                no output procedure
         DC    F'-1'               END OF LIST
***
SORTCTL  DC    AL2(SORTEND-SORTBEG)
SORTBEG  DC    C'   SORT FIELDS=(1,80,CH,A)'
         DC    C'   SUM  FIELDS=NONE'
SORTEND  EQU   *

CLEAR0TO15  DC  A(X'0000FFFF')  mask to clear bits 0-15

*
*--------------------------------------------------------*
*
HCIN     DCB DSORG=PS,DDNAME=HCIN,MACRF=GL,EODAD=FINISH
SORTIN   DCB DSORG=PS,DDNAME=SORTIN,MACRF=PM,LRECL=80
PRINT    DCB DSORG=PS,DDNAME=WARNING,MACRF=PM
GRPIN    DCB DSORG=PS,DDNAME=GRPIN,MACRF=GL,EODAD=GRPEND        M080428
GRPCLASS DCB DSORG=PS,DDNAME=GRPCLASS,MACRF=PM                  M080428
SORTOUT  DCB DSORG=PS,DDNAME=SORTOUT,MACRF=GL,EODAD=SRTEND      M080428

         CSVDYNL MF=(L,DYNLL)

         CSVDLAA ,              answer area

         CSVAPFAA ,             answer area

         CVT DSECT=YES          cvt mapping

LPAT      DSECT
LPATHDR   DS  0CL8               header section
LPATID    DS  CL4                'LPAT'
LPATCNT   DS  CL4                # of entireis in table
LPATENTRY DS  0CL45              table entry
LPATDSLN  DS  CL1                length of data set name
LPATDSN   DS  CL44               data set name
*
         END
