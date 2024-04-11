/*-------- rexx ----------*/
/* Updated from CHCKREDU to list all users   aj 20080509*/

time_start= TIME('R')
Arg parms '(' options ')' .
parms = Strip(parms)

/* analyses the environment     */
  Call REDU_INIT

If pipe_rc = 0 Then
      Rc =  REDUPIPE(parms '^' options )

time_end  = Format(TIME('E'),6,2)
txt       = REDU_TIME(time_end)
Say '         'sourcefn 'total running time:' txt

If datatype(Rc) = 'NUM' Then
   Return Rc
Else
   Return


REDU_TIME:
/*---------------------------------------------------------------------*/
/* Here starts the running time processing                             */
/*---------------------------------------------------------------------*/
Arg total_sec
txt  = total_sec
data = total_sec
hrs  = 0
min  = 0
sec  = 0
If data > 60 Then
   Do Until total_sec < 60
      total_sec = total_sec - 60
      min       = min +1
      If min > 59 Then
         Do
            hrs = hrs +1
            min = 0
         End
   End
sec = total_sec
Select
When hrs > 0 Then
   txt = hrs 'hrs' min || 'm' sec || 's'
When min > 0 Then
   txt =           min || 'm' sec || 's'
Otherwise
   txt =                      sec || 's'
End
Return txt



REDU_INIT:
/*---------------------------------------------------------------------*/
/*  Initalize the global variables                                     */
/*---------------------------------------------------------------------*/
Parse Source os invoke sourcefn .

sourcefn = Left(sourcefn,8)
debug   =  3                            /* show storage usage      */
debug   =  2                            /* show RACF Cmd           */
debug   =  1                            /* show responce time      */
debug   =  0                            /* no tracking messages    */
idxtext = '*** 'sourcefn 'INDEX',
   'created by pgm:' sourcefn,
   'version from:' ver '***'

abc   =  XRANGE('A','I'),
   || XRANGE('J','R'),
   || XRANGE('S','Z'),
   || '@$#_ '

 mbr = ' DSN:'
 'PIPE LITERAL is PIPE runnig in TSO ? | VAR QPIPE'
 pipe_rc =  rc
 infile  = "'" || USERID() || '.RACFREDU.TEMP' || "'"
 outfile = "'" || USERID() || '.CHCKREDU.TEMP' || "'"
 outindex= "'" || USERID() || '.' ,
    || strip(sourcefn) || '.INDEX' || "'"
 /*      'Pipe Literal 'idxtext' | >>' outindex */

Return


/*---------------------------------------------------------------------*/
/* End of program                                                      */
/*---------------------------------------------------------------------*/



REDUPIPE:
time_start     = TIME('R')
Parse Source os invoke sourcefn .
sourcefn = Left(sourcefn,8)
Arg parms  '^' redu_options

Call REDU_PIPE_INIT
If Pos(1,debug)> 0 Then
   Say 'INIT     'sourcefn ' running time:' TIME('E')
Call REDU_PIPE_PARM
If Pos(1,debug)> 0 Then
   Say 'PARM     'sourcefn ' running time:' TIME('E')
Call REDU_PIPE_HDR
If Pos(1,debug)> 0 Then
   Say 'HDR      'sourcefn ' RACF    time:' TIME('E')


status = SYSDSN(outindex)
If status <> 'OK' Then
   Call REDU_ALLOC '$IDXOUT$' outindex
status = SYSDSN(outfile)
If status <> 'OK' Then
   Call REDU_ALLOC '$DSNOUT$' outfile
If Debug > 0 Then
   Say 'ALLOC    'sourcefn ' running time:' TIME('E')

         /* write the output headline    */
If hdr <> '' ,
   & outfile <> '' Then
   Select
   When Pos('NOHDR',redu_options) > 0 Then
      Do
         Nop        /* bypass a new header line     */
      End
   Otherwise
      'Pipe (end ^) Literal 'hdr '|>' outfile
   End

If Left(Strip(pipe_cmd_tmp1),1) <> '<' Then
   Do
       Call REDU_ALLOC '$DSNIN$' infile

       Rc = OUTTRAP(TMPSTEM.)  /* required for MVSPIPE ;-)  */
       'Pipe  (end ^ )',
        '' Pipe_cmd_tmp1 rac_cmd/* get the data from RACF   */
       'Pipe  (END ^ )',       /*                           */
        '| STEM TMPSTEM.',     /* write the stem to output  */
        '| > ' infile          /*---------------------------*/
       If Rc > 4 Then          /* Any error greater 4 is bad*/
        Do
         Say sourcefn "Internal error RACF command: RAC " rac_cmd
         Say sourcefn "ended with     Rc=" Rc " (Exit)"
         Exit Rc
        End
   End
If Pos(1,debug) > 0 Then
   Say 'RACF     'sourcefn ' running time:' TIME('E')
                                       /*------------------------------*/
                                       /* read the data from disk      */
                                       /*------------------------------*/
Say '         reading data' Right(':',23) infile
                                       /*------------------------------*/
                                       /* save the racf return code    */
                                       /*------------------------------*/
racf_rc = Rc +0
Select
When racf_rc = 0 Then
   Nop
When racf_rc = 4 Then
   Nop
When racf_rc = 8 Then
   Nop
Otherwise
   Do
      Say 'RACF Rc='racf_rc 'executing command:'rac_cmd
      Exit racf_rc
   End
End
                                       /*------------------------------*/
                                       /* get the RACF DATA            */
 Rc = MSG('ON')             /* REQUIRED TO GET ALL DATA FROM RACF */
 'Pipe  (end ^ )',                /*                              */
    ' < 'infile,                  /*                              */
    '| Strip BLANK',              /*                              */
    '| notinside ',
       '/OTHER VOLUMES IN SET/',
       '/LEVEL  OWNER      UNIVERSAL ACCESS  YOUR ACCESS  WARNING/',
    '| Specs 1-* 1 / / Next',     /*                              */
    '' pipe_cmd_tmp2 ,            /* dynamic splitting label      */
    '| CHANGE /                / /', /*    16    BLANKS           */
    '| CHANGE /       / /',       /*     8    blanks              */
    '| CHANGE /    / /',          /*     4    blanks              */
    '| CHANGE /  / /',            /*     2    blanks              */
    '| CHANGE /  / /',            /*     2    blanks              */
    '| CHANGE /----------------/-/', /* 16    dashes              */
    '| CHANGE /-------/-/',       /*     8    dashes              */
    '| CHANGE /----/-/',          /*     4    dashes              */
    '| CHANGE /--/-/',            /*    2    dashes               */
    '| CHANGE /--/-/',            /*     2    DASHES              */
    '| OSRLUSR2',                 /* execute the specific filter  */
    '| VAR TEMPDATA',             /* store result in a variable   */
    '| >> 'outfile                /* append the results ...       */

Pipe_rc = Rc
                                       /*------------------------------*/
                                       /* adding a 0 to a value will   */
                                       /* will drop all leading zeros  */
                                       /*------------------------------*/
Pipe_Rc = Rc +racf_rc +0

If Pos(1,debug) > 0 Then
   Say 'Pipe     'sourcefn ' running time:' TIME('E')

Select
When pipe_rc = 0 Then
   Nop
When pipe_rc = 4 Then

   Do
                                       /*------------------------------*/
                                       /* we have a incomplete output  */
                                       /*------------------------------*/
      txt1 = ''
      txt2 = ''
      If Word(tempdata,1) = 'N/A' Then
         Do
            Parse var indata txt1 ' ' txt2 ' ' .
                                       /*------------------------------*/
                                       /* overwrite the prev output    */
                                       /*------------------------------*/
            'Pipe  (end ^ )',
               '| Literal *Rc='|| pipe_rc  parms '-->' txt1 txt2,
               '| cons',
               '| > 'outfile
         End
   End

When pipe_rc = 8 Then
   Do
      Parse var indata txt1 ' ' txt2 ' ' .
                                       /*------------------------------*/
                                       /* overwrite the previous output*/
                                       /*------------------------------*/
      'Pipe  (end ^ )',
         '| Literal *Rc='|| pipe_rc  parms '-->' txt1 txt2,
         '| cons',
         '| > 'outfile
   End
When pipe_rc = '13' Then
   Do
      Say '         Check available space of your "A-Disk"'
      Say Copies('-',79)
      'Q DISK A'
      Say Copies('-',79)
   End
When pipe_rc = '-122' ,
   &   pipe_rc = '-2677' Then
   Do
      Say '         increase your virtual storage machine size to maximum.'
      Say '         or'
      Say '            1.)  execute the RACF command: RAC' rac_cmd
      Say '            2.)  execute 'sourcefn 'RACF DATA A'
      Say Copies('-',79)
      'Q DISK A'
      Say Copies('-',79)
   End
When  Pipe_Rc  < 0 ,
   |    Pipe_Rc  > 8 Then
   Do
      Say 'Rc:' Right(pipe_rc,6) 'internal error occurred',
         Right('(Exit)',29)
         Exit pipe_rc
   End
Otherwise
   Nop
End

                                       /*------------------------------*/
                                       /* update the INDEX logfile     */
                                       /*------------------------------*/
'PIPE < 'OUTFILE' | COUNT LINES | STEM LINECOUNT.'
Select
When linecount.1 = 0 Then
   Do
      'Pipe Literal  'Left(outfile,38),
         || 'no HDR  available         | >>' outindex
      'DELETE' outfile
   End
When linecount.1 = 1 Then
   Do
      'Pipe Literal  'Left(outfile,38),
         || 'ICH13004I NOTHING TO LIST | >>' outindex
      'DELETE' outfile
   End
Otherwise
   'Pipe Literal  'Left(outfile,28) Right(linecount.1,8) ,
      'records ' DATE() TIME() '| >>' outindex
End


time_end  = Format(TIME('E'),6,2)
txt       = REDU_TIME(time_end)
If Pos('NOHDR',redu_options) = 0 Then
   txtmbr    = 'create' mbr
Else
   txtmbr    = 'append' mbr

Say 'Rc=' Right(rc,4) 'running time='txt txtmbr outfile
Return Rc


REDU_PIPE_PARM:
/*---------------------------------------------------------------------*/
/* This subroutine analysis the input parameters                       */
/*---------------------------------------------------------------------*/

 type    = 'LISTUSER'
 outtype = 'USER'
 rac_cmd = 'LISTUSER * OMVS '
 infile  = "'" || USERID() || '.RACFREDU.' || type || "'"
 outfile = "'" || USERID() || '.HCTOOL.'   || outtype || "'"
 pipe_cmd_tmp2 = '| joincont not leading /USER=/'

Return



REDU_PIPE_INIT:
/*---------------------------------------------------------------------*/
/* define some local variables                                         */
/*---------------------------------------------------------------------*/
/* modified by Gerd Kolberger     19 Sep 1996 17:44:09   96263         */
Rc             = 0
type           = ''
hdr            = ''
resname        = ''
active_classes = ''

parms          = Strip(parms)

 pipe_cmd_tmp1  = ' SUBCOM TSO'
 pipe_cmd_tmp2  = ''
 active_classes = ''

Return

/*---------------------------------------------------------------------*/
/* subroutine to create the Header line                                */
/*---------------------------------------------------------------------*/
REDU_PIPE_HDR:
hdr_setr     = ''
hdr_user =Left('*',
   ||      'USER'       ,10),
   || Left('NAME'       ,29),
   || Left('UsrAtt'     ,07),

hdr = hdr_user

Return

REDU_ALLOC:
/*---------------------------------------------------------------------*/
/* Dataset allocation of TSO output                                    */
/*---------------------------------------------------------------------*/
Arg dd_name dsn_name  .
If  dd_name = '' Then
   Do
      Say sourcefn 'internal error in subroutine REDU_ALLOC:'
      Say sourcefn 'ddname name missing ...        (EXIT 28)'
      Exit 28
   End
If dsn_name = '' Then
   Do
      Say sourcefn 'internal error in subroutine REDU_ALLOC:'
      Say sourcefn 'DSN name missing ...           (EXIT 28)'
      Exit 28
   End

status = SYSDSN(dsn_name)

Select
When status = 'OK' Then
   Do
      "ALLOC F("dd_name") SHR,REUSE DA("dsn_name")"
      alloc_rc = rc
   End
When status = 'DATASET NOT FOUND',
   &   dd_name= '$IDXOUT$' Then
   Do
      Address TSO
      rc = MSG('OFF')
      "FREE  F("dd_name")"
      "ALLOC F("dd_name") NEW KEEP CATALOG",
         "DA("dsn_name")",
         "SPACE(2,2)",
         "UNIT(SYSDA) UCOUNT(3)",
         "DSORG(PS)",
         "CYLINDERS LRECL(250)",
         "BLKSIZE(255)",
         "RECFM(V B)"
      alloc_rc = rc
   End
When status = 'DATASET NOT FOUND',
   &   dd_name= '$DSNOUT$' Then
   Do
      Address TSO
      rc = MSG('OFF')

      "FREE  F("dd_name")"
      "ALLOC F("dd_name") NEW KEEP CATALOG",
         "DA("dsn_name")",
         "SPACE(2,2)",
         "UNIT(SYSDA) UCOUNT(3)",
         "DSORG(PS)",
         "CYLINDERS LRECL(32756)",
         "BLKSIZE(32760)",
         "RECFM(V B)"
      alloc_rc = rc
   End
When status = 'DATASET NOT FOUND',
   &   dd_name= '$DSNIN$' Then
   Do
      Address TSO
      rc = MSG('OFF')
      "FREE  F("dd_name")"
      "ALLOC F("dd_name") NEW KEEP CATALOG",
         "DA("dsn_name")",
         "SPACE(2,2)",
         "UNIT(SYSDA) UCOUNT(3)",
         "DSORG(PS)",
         "CYLINDERS LRECL(32756)",
         "BLKSIZE(32760)",
         "RECFM(V B)"
      alloc_rc = rc
   End
Otherwise
   Do
      Say sourcefn 'internal error in subroutine REDU_ALLOC:'
      Say sourcefn 'status of DSN:' dsn_name 'is:' status
      Exit 4
   End
End

Address TSO
rc = MSG('ON')

If   alloc_rc <> 0 Then
   Do
      Say 'The allocation of the DSN:' dsn_name
      Say 'ended with Rc =' alloc_rc' processing terminated.(EXIT)'
      Exit alloc_rc
   End

Return

