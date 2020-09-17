using DSP
using Test

const NAME = "Findpeaks: "

@testset "$NAME Single Gaussian peak" begin
    gaussian(x,μ,σ) = 1/sqrt(2*π)/σ*exp(-((x-μ)^2)/2/σ^2)
    x = collect(range(1,stop=1000,length=1000))
    μ = rand(x)
    data = gaussian.(x,μ,rand(x)/3)

    p, _ = findpeaks(data)
    @test length(p) == 1
    @test p[1] == μ

    p, _ = findpeaks(data,x)
    @test length(p) == 1
    @test p[1] == μ
end


@testset "$NAME Prominence" begin
    gaussian(x,μ,σ) = exp(-((x-μ)^2)/2/σ^2)

    x = range(0., stop = 1., length = 1000) |> collect

    positions = [1, 2, 3, 5, 7, 8]/10;
    amps = [3, 7, 5, 5, 4, 5];
    widths = [1, 3, 3, 4, 2, 3]/100;

    base = 4 * cos.(2π * x);
    signal = ( a * gaussian.(x, μ, σ) for (a, μ, σ) in zip(amps, positions, widths) )
    data = sum(signal) + base

    peaks, _ = findpeaks(data, x, min_prom=4.)
    
    @test length(peaks) == 2

    expected_peak_1 = argmin(abs.(x .- positions[2])) # global highest peak
    expected_peak_2 = argmin(abs.(x .- positions[4])) # lowest peak

    # check peaks are around expected - may be shifted because of background
    @test abs(peaks[1] - expected_peak_1) < 20
    @test abs(peaks[2] - expected_peak_2) < 20
end

@testset "$NAME Threshold" begin
    y = [0., 1., 3., 1., 4., 5., 3., 0., 2., 5., 4., 0.]
    
    @test Set(findpeaks(y, threshold=3.1)[1]) == Set([])
    @test Set(findpeaks(y, threshold=2.1)[1]) == Set([])
    @test Set(findpeaks(y, threshold=1.1)[1]) == Set([3])
    @test Set(findpeaks(y, threshold=0.1)[1]) == Set([3, 6, 10])
    @test Set(findpeaks(y, threshold=0.0)[1]) == Set([3, 6, 10])
end

@testset "$NAME Min. Distance" begin
    y = [0., 1., 3., 1., 4., 5., 3., 0., 2., 5., 4., 0.]
    
    @test Set(findpeaks(y, min_dist=4)[1]) == Set([6])
    @test Set(findpeaks(y, min_dist=3)[1]) == Set([6, 10])
    @test Set(findpeaks(y, min_dist=2)[1]) == Set([3, 6, 10])
    @test Set(findpeaks(y, min_dist=0)[1]) == Set([3, 6, 10])
    @test Set(findpeaks(y, min_dist=0)[1]) == Set([3, 6, 10])
end

@testset "$NAME Min. Height" begin
    y = [0., 1., 3., 1., 4., 5., 3., 0., 2., 5., 4., 0.]
    
    @test Set(findpeaks(y, min_height=6.0)[1]) == Set([])
    @test Set(findpeaks(y, min_height=4.9)[1]) == Set([6, 10])
    @test Set(findpeaks(y, min_height=2.9)[1]) == Set([3, 6, 10])
end

@testset "$NAME Plateaus" begin
    y = [0., 1., 3., 3., 3., 1., 4., 5., 3., 0., 0., 1., 5., 5., 4., 0.]
    
    @test Set(findpeaks(y)[1]) == Set([4, 8, 13])
    @test Set(findpeaks(y, min_plateau_points=1)[1]) == Set([4, 8, 13])
    @test Set(findpeaks(y, min_plateau_points=2)[1]) == Set([4, 13])
    @test Set(findpeaks(y, min_plateau_points=3)[1]) == Set([4])
    @test Set(findpeaks(y, min_plateau_points=4)[1]) == Set([])

    @test Set(findpeaks(y, max_plateau_points=2)[1]) == Set([8, 13])
    @test Set(findpeaks(y, max_plateau_points=1)[1]) == Set([8])
    @test Set(findpeaks(y, max_plateau_points=0)[1]) == Set([])

    @test Set(findpeaks(y, min_plateau_points=2, max_plateau_points=2)[1]) == Set([13])
end

@testset "$NAME Two Plateaus next to each other" begin
    y = [0., 3., 3., 5., 5., 1.]
    @test Set(findpeaks(y)[1]) == Set([4])
end

@testset "$NAME Empty inputs" begin
    y1 = Float64[]
    x1 = Int64[]

    @test isempty(findpeaks(y1)[1])
    @test findpeaks(y1, x1)[1] == empty(x1)

    y2 = Integer[]
    x2 = String[]

    @test isempty(findpeaks(y2)[1])
    @test findpeaks(y2, x2)[1] == empty(x2)
end

@testset "$NAME Non-equal data lengths" begin
    y = [1.0, 2.0, 1.0]
    x = [2.0]

    @test_throws ArgumentError findpeaks(y, x)
end
