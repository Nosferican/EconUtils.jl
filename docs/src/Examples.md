# Examples

- Set up

```@example Tutorial
using DataFrames, EconUtils
srand(0)
srand(0)
df = DataFrame(PID = repeat(1:10, inner = 10),
               TID = repeat(Date(2000):Dates.Month(2):(Date(2000) + Dates.Month(18)), outer = 10),
               y = zeros(100), x1 = rand(100), x2 = rand(100), x3 = sample(["A","B","C"], 100),
               x4 = repeat(sample(["True","False"], 10), inner = 10), x5 = repeat(1:10, inner = 10),
               z1 = rand(100), Z1 = rand(100))
df[:y] = df[:x1] + df[:x2] + get.(Dict([("A", -1),("B", 0), ("C", 1)]), df[:x3], 0) + (df[:x4] .== "True") +
    repeat(rand(10), inner = 10) + rand(100)
categorical!(df, [:PID, :x3, :x4, :x5])
df[:TID] = CategoricalVector(df[:TID], ordered = true)
head(df)
print() # hide
```
