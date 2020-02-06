#!/bin/bash
# Copyright 2017 Actian Corporation

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

# This script is designed to report information about the Vector (or Vector-H) Mix Max indexes.
# These indexes indicate the order in which data is stored on disk, and are important to query
# performance.

usage()
{
        echo "Usage: ${0} -d database name -o table owner -t table -c column name  [-p partition number -h]"

cat <<-EOF
                        -d: database        - Database name.
                        -o: owner           - Table owner.
                        -t: table           - Table name.
                        -c: column          - Column name.
                        -p: partition num   - Partition number.
                        -h                  - Help
EOF
        exit -1
}
#
# Global ENV Variables
#
AV_DATABASE=""
AV_TABLEOWNER=""
AV_TABLENAME=""
AV_COLUMNNAME=""
AV_PARTITIONNUM=""

    while getopts "d:o:t:c:p:h" i
    do
     case "$i" in
             d)
                     export AV_DATABASE=${OPTARG}
                     ;;

             o)
                     export AV_TABLEOWNER=${OPTARG}
                     ;;
                    
             t)
                     export AV_TABLENAME="${OPTARG}"
                     ;;
             c)
                     export AV_COLUMNNAME=${OPTARG}
                     ;;
             p)
                     export AV_PARTITIONNUM=${OPTARG}
                     ;;
             h)
                     usage
                     ;;
             *)
                     usage
                     ;;
     esac
    done

# Default the partition to all partitions (for both partitioned and non partitioned tables)
# or add the "@" character if a partition is specified
# This is a tidy test for partitioning and forming the x100 name

if [ "${AV_DATABASE}" = "" ]
then
        usage
fi
if [ "${AV_TABLEOWNER}" = "" ]
then
        usage
fi
if [ "${AV_TABLENAME}" = "" ]
then
        usage
fi
if [ "${AV_COLUMNNAME}" = "" ]
then
        usage
fi
if [ "${AV_PARTITIONNUM}" = "" ]
then
        AV_PARTITIONNUM="%"
fi
if [ -f ./avENV.sh ]
then
        . ./avENV.sh
else
        echo "Missing the 'avENV.sh' program."
        exit -1
fi
#
## Move getting the DDL higher up so that we can test if table is partitioned.
## Get the datatype for the column, so we can store the values later in the temp table
## Dumps the table schema to a file in /tmp then grabs the column datatype from that
#
copydb -u${AV_TABLEOWNER} ${AV_DATABASE} ${AV_TABLENAME} >copydb.log 2>&1
ERRORS=$(grep E_ copydb.log)
if [ "${ERRORS}" != "" ]
then
        echo "Problems accessing database ${AV_DATABASE} and table ${AV_TABLENAME} owned by ${AV_TABLEOWNER} - please check details and permissions."
        exit 1
fi

# Provide a default if the above didn't work for some reason
#
## Add a space to differentiate beween say col1 and col10
## Treat timestamps and dates as integers
#
CTYPE=$(grep "${AV_COLUMNNAME} " copy.in |cut -d' ' -f2|head -1)
CTYPETRUNC=$(echo "${CTYPE}" | cut -d "(" -f1 )
#
if [ "${CTYPETRUNC}" = "" ] || [ "${CTYPETRUNC}" = "ansidate" ] || [ "${CTYPETRUNC}" = "timestamp" ]
then
        CTYPE="integer8"
fi
#
##echo ${CTYPE}
##exit
#
## Check if table is partitioned
if [ -z "`grep 'partition = (HASH' copy.in`" ]
then
        ## Not Partitioned
        MATCHFUNC="=="
        AV_TABLENAMEX100="_${AV_TABLEOWNER}S${AV_TABLENAME}"
else
        ## Partitioned
        MATCHFUNC="like"
        AV_TABLENAMEX100="_${AV_TABLEOWNER}S${AV_TABLENAME}@${AV_PARTITIONNUM}"
fi
#
rm copy.out copy.in copydb.log
#
## Include the partition spec in the x100 table name
AV_COLUMNNAMEX100="_${AV_COLUMNNAME}"
DATAFILE="/tmp/${3}${4}.dat"
DATATABLE="minmax_deleteme"
DATATABLE2="minmax2_deleteme"
DATATABLE3="minmax3_deleteme"
#
##  Include partition spec
echo "Database: ${AV_DATABASE}, Owner: ${AV_TABLEOWNER}, Table/Partition: ${AV_TABLENAME}/${AV_PARTITIONNUM} [ ${AV_TABLENAMEX100} ], Column: ${AV_COLUMNNAME} [ ${AV_COLUMNNAMEX100} Datatype: ${CTYPE} ]"
#
if [ -d "$II_SYSTEM/ingres/data/vectorwise/$AV_DATABASE/CBM" ]
then
        ## Vector
        LOCKDIR="$II_SYSTEM/ingres/data/vectorwise/$AV_DATABASE/CBM"
else
        ## VectorH
        LOCKDIR="$II_SYSTEM/ingres/data/vectorwise/$AV_DATABASE"
fi
#
# Call the x100 client to run some x100 algebra directly, to get data from internal data structs

x100_client --port `cat ${LOCKDIR}/lock | head -1` --passfile $II_SYSTEM/ingres/data/vectorwise/$AV_DATABASE/authpass -o raw << EOF > ${DATAFILE} 2>/dev/null

# Join to the minmax table (restrict to 1 column)
HashJoin01 (
         SysScan('minmax', [ 'table_name', 'column_nr', 'minmax_row', 'minmax_minval', 'minmax_maxval' ] )
                ,[ table_name, column_nr ] [ minmax_row, minmax_minval, minmax_maxval ]
        ,HashJoin01 (
                 Select(
                         SysScan('columns', ['column_name', 'table_id', 'column_offset'])
                        ,==(column_name, '${AV_COLUMNNAMEX100}')
                 )
                        , [ table_id ] [ column_name, column_offset ]
                ,Select(
                         SysScan('tables', ['table_name', 'table_id'])
#  Change the condition to a like
# Matching function depends if table is partitioned
#                       ,==(table_name, '${AV_TABLENAMEX100}')
#                       ,like(table_name, '${AV_TABLENAMEX100}')
                        ,${MATCHFUNC}(table_name, '${AV_TABLENAMEX100}')
                 )
                        ,[ table_id ] [ table_name ]
         )
                ,[ table_name, column_offset ] [ table_name, column_name ]
)
;

EOF
#
##  Debug the x100 output, if needed
ROWS=`cat ${DATAFILE} | wc -l `
echo MinMax block count returned from x100 query was ${ROWS}
#
if [ ${ROWS} = 0 ]
then
    echo No rows returned from x100 query: unable to continue, please fix the problem.
    echo This might be because you specified a non-existent table or column name - this is not
    echo explicitly validated.
#
    exit
fi
#
#
## Now to work with the output from x100 data and look for data range overlaps
## Using SQL to do this, with a few temp table steps as below.
## If debug output is needed, switch the variable below.
#
GO='\p\g'       # Produces debug level output if needed. Also need to remove \silent below.
GO='\g'         # Default to no Debug output

sql ${AV_DATABASE} << EOF
\silent

drop table if exists ${DATATABLE}; ${GO}

create table ${DATATABLE} (
         RowId          integer8        not null
        ,MinValue       ${CTYPE}        not null
        ,MaxValue       ${CTYPE}        not null
        ,TableName      varchar(30)     not null
        ,ColName        varchar(30)     not null
)
;${GO}

--  Fix order of table name and column name
copy table ${DATATABLE} (
         RowId          = 'c0|'
        ,MinValue       = 'c0|'
        ,MaxValue       = 'c0|'
        ,ColName        = 'c0|'
        ,TableName      = 'c0nl'
)
from '${DATAFILE}'
;${GO}

drop table if exists ${DATATABLE2};
drop table if exists ${DATATABLE3};
;${GO}


create table ${DATATABLE2} as
        select
                 row_number() over (partition by TableName order by RowId) as LineNum
                ,RowId
                ,MinValue
                ,MaxValue
                ,TableName
          from
                 ${DATATABLE}
;${GO}

create table ${DATATABLE3} as
select
         mm1.TableName
        ,mm1.LineNum
        ,mm1.MinValue as mm1_MinValue
        ,mm1.MaxValue as mm1_MaxValue
        ,mm2.MinValue as mm2_MinValue
        ,mm2.MaxValue as mm2_MaxValue
        ,mm2.RowId - mm1.RowId as rows
        ,case
                when mm1.MaxValue > mm2.MinValue then 1
                else 0
         end as OverLap
  from
         ${DATATABLE2} mm1
        ,${DATATABLE2} mm2
 where
        mm1.TableName = mm2.TableName
   and  mm1.LineNum = mm2.LineNum - 1
;${GO}


-- Debug level output only

-- SELECT * from ${DATATABLE3}
-- ORDER BY
--       TableName
--      ,LineNum
-- ;${GO}
commit;
;${GO}

EOF

sql ${AV_DATABASE} << EOF

-- Final output.
-- If SortedPct is not 100, then the Min Max index is not fully sorted.
-- If SortedPct is 0, then the data in the index is not sorted at all.

SELECT
         TableName
        ,sum(OverLap) as OverLaps
        ,count(*) as Total_index_blocks
        ,100.0 - decimal((decimal(sum(OverLap))/decimal(count(*)))*100.0,5,2) as SortedPct
FROM
         ${DATATABLE3}
GROUP BY
         TableName
;${GO}

drop table ${DATATABLE};
drop table ${DATATABLE2};
drop table ${DATATABLE3};
commit;
${GO}

EOF
#
echo
echo
echo In the table above, the values to pay attention to are in the sortedpct column.
echo

echo If SortedPct is not 100, then the Min Max index for this table/column is not fully sorted.
echo If SortedPct is 0, then the data in the index is not sorted at all.
echo

echo The latter result means that more disk blocks will have to be scanned to eliminate unnecessary
echo rows. Improving the sort order of data means fewer blocks need to be examined, so less disk IO.
echo

echo 'To sort data, create an index on the column to be sorted (check the manual for syntax).'
echo

#cat ${DATAFILE}
rm -f ${DATAFILE}
