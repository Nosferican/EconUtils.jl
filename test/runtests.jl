
using EconUtils
using Test
using DataFrames

df = DataFrames(x = 1:5)

# write your own tests here
@test df == DataFrames(x = 1:5)
