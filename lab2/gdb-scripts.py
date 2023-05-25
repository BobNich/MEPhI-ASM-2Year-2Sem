define print_min_array
  set $count = *(unsigned char *) &cols 
  set $min_array = (long *) &min_array

  set $i = 0
  printf "Min array:\n"
  while ($i < $count)
    printf "%d\t", *(long *)($min_array + $i)
    set $i = $i + 1
  end
  printf "\n"
end

define print_matrix
  set $rows = *(unsigned char *) &rows
  set $cols = *(unsigned char *) &cols
  set $matrix = (long *) &matrix
  set $i = 0
  set $j = 0
  printf "Matrix:\n"
  while ($i < $rows)
    set $j = 0
    while ($j < $cols)
      printf "%d\t", *(long*)($matrix + ($i * $cols) + $j)
      set $j = $j + 1
    end
    printf "\n"
    set $i = $i + 1
  end
  printf "\n"
end