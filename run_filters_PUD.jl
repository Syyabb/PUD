using Printf
using NPZ
include("util.jl")
include("kmeans_filters.jl")
include("quantum_filters.jl")

log_file = open("run_filters.log", "a")

for name in ARGS

    top_rates = [0.4, 0.4, 0.7, 0.8, 0.7, 0.7, 0.8, 0.8, 0.8, 1, 1, 1, 1, 1, 1, 1, 1]
    reps = npzread("output/reps3.npy")'
    n = size(reps)[2]

    step = parse(Int64, name)
    eps = round(Int, 500 * top_rates[step+1] * 0.12)



    if step == 10
        eps = 4800 #round(Int, 500 * top_rates[step+1] * 1)
        #eps = 20
    end

    if step == 9
        eps = 4800#round(Int, 500 * top_rates[step+1] * 1)
        #eps = 20

    end
    removed = round(Int, 1.5 * eps)


    @printf("%s: Running PCA filter\n", name)
    reps_pca, U = pca(reps, 1)
    pca_poison_ind = k_lowest_ind(-abs.(mean(reps_pca[1, :]) .- reps_pca[1, :]), round(Int, 1.5 * eps))
    poison_removed = sum(pca_poison_ind[end-eps+1:end])
    clean_removed = removed - poison_removed
    @show poison_removed, clean_removed
    @printf(log_file, "%s-pca: %d, %d\n", name, poison_removed, clean_removed)
    npzwrite("output/$(name)/mask-pca-target.npy", pca_poison_ind)

    #@printf("%s: Running kmeans filter\n", name)
    #kmeans_poison_ind = .! kmeans_filter2(reps, eps)
    #poison_removed = sum(kmeans_poison_ind[end-eps+1:end])
    #clean_removed = removed - poison_removed
    #@show poison_removed, clean_removed
    #@printf(log_file, "%s-kmeans: %d, %d\n", name, poison_removed, clean_removed)
    #npzwrite("output/$(name)/mask-kmeans-target.npy", kmeans_poison_ind)


    @printf("%s: Running quantum filter\n", name)
    quantum_poison_ind = .!rcov_auto_quantum_filter(reps, eps) #
    poison_removed = sum(quantum_poison_ind[end-eps+1:end])
    clean_removed = removed - poison_removed
    @show poison_removed, clean_removed
    @printf(log_file, "%s-quantum: %d, %d\n", name, poison_removed, clean_removed)
    npzwrite("output/$(name)/mask-rcov-target.npy", quantum_poison_ind)

end
