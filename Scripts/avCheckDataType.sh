#!/bin/bash

if [ $# -ne 3 ]
then
    echo "Usage: ${0} dbname owner tablename"
    exit
fi

DBNAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
OWNER=$(echo "$2" | tr '[:upper:]' '[:lower:]')
TABLE=$(echo "$3" | tr '[:upper:]' '[:lower:]')

function get_inttype {
        SQL_STMT=$(echo "SELECT
                     CASE
                            WHEN max(cast($1 as bigint)) < 128 and min(cast($1 as bigint)) > -129 
                              THEN 'tinyint'
                            WHEN max(cast($1 as bigint)) < 32768 and min(cast($1 as bigint)) > -32769 
                              THEN 'smallint'
                            WHEN max(cast($1 as bigint)) < 2147483648 and min(cast($1 as bigint)) > -2147483649 
                              THEN 'integer'
                            ELSE 'bigint'
                     END AS sqltyp
              FROM   $OWNER.$TABLE a\g")
         echo $(sql -S $DBNAME <<< "$SQL_STMT")
}  

function get_precscale {
        SQL_STMT=$(echo "SELECT  '(' ||
                                 to_char(length(to_char(cast(trunc(max(abs($1)),0) as bigint))) + max(length(to_char(abs($1-trunc($1,0)))))-2) ||
                                 ',' ||
                                 to_char(max(length(to_char(abs($1-trunc($1,0)))))-2) ||
                                 ')' AS decspec
              FROM   $OWNER.$TABLE a\g")
         echo $(sql -S $DBNAME <<< "$SQL_STMT")
}  

declare -a COL_NAME
declare -a COL_TYPE
declare -a COL_REAL
declare -a COL_NULL
i=0
while read -r line
do
       COL_NAME[$i]=$(echo ${line} | awk '{print $1}')
       COL_TYPE[$i]=$(echo ${line} | awk '{print $2}' | tr '[:upper:]' '[:lower:]')
       (( i++ ))
done < <(sql -S $DBNAME <<< "select column_name , column_datatype from iicolumns where table_name='$TABLE' and table_owner = '$OWNER' order by column_sequence\g")

#echo ${COL_NAME[@]}
#echo ${COL_TYPE[@]}
#echo ${#COL_TYPE[@]}
#select length(to_char(cast(trunc(max(abs(x)),0) as integer))) digits, max(length(to_char(abs(x-trunc(x,0)))))-2 decimals from testdecimal\g

echo COLNAME COLTYPE SUGGESTED_TYPE NULL/NOT NULL
echo ------- ------- -------------- -------------
for((i=0;i<${#COL_NAME[@]};i++))
do
      COL="${COL_NAME[$i]}"
      if [ "${COL_TYPE[$i]}" == "varchar" ] || [ "${COL_TYPE[$i]}" == "char" ]
      then
         SQLSTMT=$(echo "SELECT
                     CASE
                            WHEN min(
                                   CASE
                                          WHEN $COL IS integer OR $COL IS null THEN 1
                                          ELSE 0
                                   END) = 1 THEN 'integer'
                            WHEN min(
                                   CASE
                                          WHEN $COL IS decimal OR $COL IS null THEN 1
                                          ELSE 0
                                   END) = 1 THEN 'decimal'
                            WHEN min(
                                   CASE
                                          WHEN $COL IS float OR $COL IS null THEN 1
                                          ELSE 0
                                   END) = 1 THEN 'float'
                            ELSE '${COL_TYPE[$i]}('
                                          ||trim(max(length($COL)+1))
                                          ||')'
                     END AS sqltyp,
                     CASE
                            WHEN max(
                                   CASE
                                          WHEN $COL IS NULL THEN 1
                                          ELSE 0
                                   END) = 0 THEN 'NOT NULL,'
                            ELSE 'NULL,'
                     END AS constr
              FROM   $OWNER.$TABLE a\g")
      else
          SQLSTMT=$(echo "SELECT
                     CASE
                            WHEN min(
                                   CASE
                                          WHEN $COL IS integer OR $COL IS null THEN 1
                                          ELSE 0
                                   END) = 1 THEN 'integer'
                            WHEN min(
                                   CASE
                                          WHEN $COL IS decimal OR $COL IS null THEN 1
                                          ELSE 0
                                   END) = 1 THEN 'decimal'
                            WHEN min(
                                   CASE
                                          WHEN $COL IS float OR $COL IS null THEN 1
                                          ELSE 0
                                   END) = 1 THEN 'float'
                            ELSE '${COL_TYPE[$i]}'
                     END AS sqltyp,
                     CASE
                            WHEN max(
                                   CASE
                                          WHEN $COL IS NULL THEN 1
                                          ELSE 0
                                   END) = 0 THEN 'NOT NULL,'
                            ELSE 'NULL,'
                     END AS constr
              FROM   $OWNER.$TABLE a\g")
      fi
      if  [[ ${COL_TYPE[$i]} == *date ]] || [[ ${COL_TYPE[$i]} == timestamp* ]] ;
      then
           SQLSTMT=$(echo "SELECT
                     max('${COL_TYPE[$i]}') AS sqltyp,
                     CASE
                            WHEN max(
                                   CASE
                                          WHEN $COL IS NULL THEN 1
                                          ELSE 0
                                   END) = 0 THEN 'NOT NULL,'
                            ELSE 'NULL,'
                     END AS constr
              FROM   $OWNER.$TABLE a\g")
      fi
#      echo $SQLSTMT
      echo
      while read -r line
         do 
           newtype="$(echo ${line} | awk '{print $1}')"
           nulls="$(echo ${line} | awk '{$1=""; print $0}')"
           if [ $newtype == 'integer' ]
           then
               echo ${COL_NAME[$i]} ${COL_TYPE[$i]} $(get_inttype ${COL_NAME[$i]}) $nulls
           elif [ $newtype == 'decimal' ]
           then
               echo ${COL_NAME[$i]} ${COL_TYPE[$i]} "decimal"$(get_precscale ${COL_NAME[$i]}) $nulls
           else
               echo ${COL_NAME[$i]} ${COL_TYPE[$i]} $newtype $nulls
           fi
           done < <(sql -S ${DBNAME} <<< "$SQLSTMT")
done
