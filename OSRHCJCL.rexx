 /* rexx */                                                             00010000
 /* create JCL and automatically put the system name and userid         00020000
                                       AndrewJ 2008 Apr 21 */           00020300
 /* replace SYS1 with USERID for output datasets                        00020401
                                       AndrewJ 2008 Apr 22 */           00020501
 /* updated to read in another file for group class control checking    00020602
                                       AndrewJ 2008 Apr 28 */           00020702
 /* updated to provide an option: TRNEXPND to specify whether to        00020806
    list all transactions or not                                        00020906
                                  andrewJ 2008 Apr 29 */                00021006
 /* produce a combined summary list of both RACF  and OSR               00021109
    privilege ids                                                       00021209
                                  andrewJ 2008 May 09 */                00021309
 arg  arg1 arg2                                         /*20080429*/    00021409
 queue "//" || left(mvsvar(sysname),8) || ,                             00021509
       " JOB  IBM,SP,CLASS=A,MSGCLASS=X," || ,                          00021609
       "NOTIFY=" || sysvar(sysuid)                                      00021709
 queue "//STEP1    EXEC PGM=OSRHC                                 "     00021809
 queue "//STEPLIB  DD   DISP=SHR,DSN=SYS1.HCTOOL.LMD              "     00021909
 queue "//HCIN     DD   DISP=SHR,DSN=SYS1.HCTOOL.PARMLIB(HC)      "     00022009
 queue "//GRPIN    DD   DISP=SHR,DSN=SYS1.HCTOOL.PARMLIB(GRPCLASS)"     00022109
 queue "//WARNING  DD   SYSOUT=*,LRECL=80                         "     00022209
 queue "//GRPCLASS DD   DISP=(NEW,PASS),DSN=&&GRPCLS,UNIT=SYSDA,  "     00022309
 queue "//     DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)," || ,             00022409
       "SPACE=(TRK,(30,30),RLSE)"                                       00022509
 queue "//SORTIN   DD   DISP=(NEW,PASS),DSN=&&SORTIN,UNIT=SYSDA,  "     00022609
 queue "//     DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)," || ,             00022709
       "SPACE=(TRK,(30,30),RLSE)"                                       00022809
 queue "//SORTWK1  DD   UNIT=SYSDA,SPACE=(CYL,(20,9))             "     00022909
 queue "//SYSPRINT DD   SYSOUT=*                                  "     00023009
 queue "//SYSOUT   DD   DUMMY                                     "     00023109
 queue "//SORTOUT  DD   DISP=(NEW,PASS),DSN=&&SORTOU,UNIT=SYSDA,  "     00023209
 queue "//     DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)," || ,             00023309
       "SPACE=(TRK,(30,30),RLSE)"                                       00023409
 queue "//*                                                       "     00023509
 queue "//STEP2    EXEC PGM=IKJEFT01                              "     00023609
 queue "//SYSEXEC  DD  DISP=SHR,DSN=SYS1.HCTOOL.PARMLIB           "     00023709
 queue "//GRPCLASS DD  DISP=(OLD,PASS),DSN=&&GRPCLS               "     00023809
 queue "//FILEIN   DD  DISP=(OLD,PASS),DSN=&&SORTOU               "     00023909
 queue "//IDS4OSR  DD  DISP=SHR,DSN=" || sysvar(sysuid) || ,            00024009
       ".HCTOOL.IDS4OSR  vb,lrecl=27994"                                00024109
 queue "//SYSTSPRT DD  SYSOUT=*                                   "     00024309
 queue "//SYSTSIN  DD  *                                          "     00024409
 queue "  %OSRID4HC " || arg2                             /*20080429*/  00024509
 queue "/*                                                        "     00024609
 queue "//* RSCEXPND is optional                                  "     00024709
 queue "//* RSCEXPND will list all specific profiles for a generic" ||, 00024809
       " profile"                                                       00024909
 queue "//*                                                       "     00025009
 queue "//STEP3    EXEC PGM=IKJEFT01                              "     00025109
 queue "//SYSEXEC  DD  DISP=SHR,DSN=SYS1.HCTOOL.PARMLIB           "     00025209
 queue "//GRPCLASS DD  DISP=(OLD,DELETE),DSN=&&GRPCLS             "     00025309
 queue "//FILEIN   DD  DISP=(OLD,DELETE),DSN=&&SORTOU             "     00025409
 queue "//FILEOU   DD  UNIT=SYSDA,DISP=(NEW,PASS),DSN=&&ID2HC,    "     00025509
 queue "//   DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)," || ,               00025609
       "SPACE=(TRK,(50,50),RLSE)"                                       00025709
 queue "//SYSTSPRT DD  SYSOUT=*                                   "     00025909
 queue "//SYSTSIN  DD  *                                          "     00026009
 queue "  %OSRHC4ID GRPEXPND " || arg2                     /*20080429*/ 00026109
 queue "/*                                                        "     00026209
 queue "//* GRPEXPND & RSCEXPND are all optional                  "     00026309
 queue "//* GRPEXPND will list all userids in a user group        "     00026409
 queue "//* RSCEXPND will list all specific profiles for a generic" ||, 00026509
       " profile"                                                       00026609
 queue "//*                                                       "     00026709
 queue "//STEP4    EXEC PGM=ICETOOL,REGION=4096K                  "     00026809
 queue "//TOOLMSG  DD SYSOUT=*                                    "     00026909
 queue "//DFSMSG   DD SYSOUT=*                                    "     00027009
 queue "//PRFILE   DD DISP=(OLD,DELETE),DSN=&&ID2HC               "     00027109
 queue "//INFILE   DD UNIT=SYSDA,DISP=(NEW,PASS),DSN=&&ID2HC2,    "     00027209
 queue "//   DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)," || ,               00027309
       "SPACE=(TRK,(50,50),RLSE)"                                       00027409
 queue "//OUFILE   DD UNIT=SYSDA,DISP=(NEW,PASS),DSN=&&ID2HC3,    "     00027509
 queue "//   DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920)," || ,               00027609
       "SPACE=(TRK,(50,50),RLSE)"                                       00027709
 queue "//TOOLIN   DD *                                              "  00027809
 queue " SORT FROM(PRFILE) USING(PREP) TO(INFILE)                    "  00027909
 queue " SORT FROM(INFILE) USING(SORT) TO(OUFILE)                    "  00028009
 queue " DISPLAY FROM(OUFILE) LIST(OSRS4ID)                         -"  00028109
 queue "   TITLE('" || left(mvsvar(sysname),8) || ,                     00028209
       " Privilege IDs against OSRs by " || sysvar(sysuid) || ,         00028309
       "')  -"                                                          00028409
 queue "   DATE(4MD/) TIME PAGE LINES(999) BREAK(1,8,CH)            -"  00028509
 queue "   HEADER('Userid   Group    Access   OSR Prof. or Class ') -"  00028609
 queue "   ON(1,80,CH)                                               "  00028709
 queue " SORT FROM(OUFILE) USING(PRIV) TO(PRIVILID)                  "  00028809
 queue "/*                                                           "  00028909
 queue "//OSRS4ID  DD DISP=SHR,DSN=" || sysvar(sysuid) || ,             00029009
       ".HCTOOL.OSRS4ID  lrecl=121,fba"                                 00029109
 queue "//PRIVILID DD UNIT=SYSDA,DISP=(NEW,PASS),DSN=&&PRIVID,       "  00029209
 queue "//   DCB=(RECFM=FB,LRECL=8,BLKSIZE=8000)," || ,                 00029309
       "SPACE=(TRK,(15,15),RLSE)"                                       00029409
 queue "//PREPCNTL DD *                                              "  00029509
 queue " SORT  FIELDS=(1,8,CH,A,28,52,CH,A,19,1,AQ,A,10,8,CH,A)      "  00029609
 queue " ALTSEQ CODE=(D9E5)                                          "  00029709
 queue " SUM   FIELDS=NONE                                           "  00029809
 queue " END                                                         "  00029909
 queue "/*                                                           "  00030009
 queue "//SORTCNTL DD *                                              "  00030109
 queue " SORT  FIELDS=(1,8,CH,A,28,52,CH,A)                          "  00030209
 queue " SUM   FIELDS=NONE                                           "  00030309
 queue " END                                                         "  00030409
 queue "/*                                                           "  00030509
 queue "//PRIVCNTL DD *                                              "  00030609
 queue " INREC FIELDS=(1,10)                                         "  00030709
 queue " OMIT  COND=(10,1,CH,EQ,C'g')                                "  00030809
 queue " SORT  FIELDS=(1,8,CH,A)                                     "  00030909
 queue " SUM   FIELDS=NONE                                           "  00031009
 queue " OUTREC FIELDS=(1,8)                                         "  00031109
 queue " END                                                         "  00031209
 queue "/*                                                           "  00031309
 queue "//STEP5    EXEC PGM=IKJEFT01                                 "  00031409
 queue "//SYSEXEC  DD  DISP=SHR,DSN=SYS1.HCTOOL.PARMLIB              "  00031509
 queue "//PRIVILID DD  DISP=(OLD,PASS),DSN=&&PRIVID                  "  00031609
 queue "//SYSTSPRT DD  SYSOUT=*                                      "  00031809
 queue "//SYSTSIN  DD  *                                             "  00031909
 queue "  %OSRIDXMT " arg1                                              00032009
 queue "/*                                                           "  00032109
 queue "//STEP6    EXEC PGM=IKJEFT01                                 "  00032209
 queue "//STEPLIB  DD  DISP=SHR,DSN=SYS1.HCTOOL.LMD                  "  00032309
 queue "//SYSEXEC  DD  DISP=SHR,DSN=SYS1.HCTOOL.PARMLIB              "  00032409
 queue "//REXX     DD  DISP=SHR,DSN=SYS1.HCTOOL.PARMLIB              "  00032509
 queue "//SYSTSPRT DD  SYSOUT=*                                      "  00032709
 queue "//SYSTSIN  DD  *                                             "  00032809
 queue "  %OSRLUSR1 "                                                   00032909
 queue "/*                                                           "  00033009
 queue "//STEP7    EXEC PGM=IKJEFT01                                 "  00033109
 queue "//SYSEXEC  DD  DISP=SHR,DSN=SYS1.HCTOOL.PARMLIB              "  00033209
 queue "//PRIVILID DD  DISP=(OLD,DELETE),DSN=" || sysvar(sysuid) || ,   00033310
       ".HCTOOL.PRIVILID "                                              00033410
 queue "//USERIN   DD  DISP=(OLD,DELETE),DSN=" || sysvar(sysuid) || ,   00033512
       ".HCTOOL.USER "                                                  00033611
 queue "//IDSUM    DD  DISP=SHR,DSN=" || sysvar(sysuid) || ,            00033709
       ".HCTOOL.IDSUM "                                                 00033809
 queue "//SYSTSPRT DD  SYSOUT=*                                      "  00034009
 queue "//SYSTSIN  DD  *                                             "  00034109
 queue "  %OSRLUSR3 "                                                   00034209
 queue "//"                                                             00034309
                                                                        00035009
  "execio * diskw jclin (finis "                                        00160000
                                                                        00180000
 exit(0)                                                                00190000
                                                                        00200000
