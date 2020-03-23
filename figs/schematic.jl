using PyPlot
using Statistics

Statistics.mean(x::Real,y::Real) = (x+y)/2

x = [0.5,1.0,2.0]
xint = [mean(x[i],x[i+1]) for i in 1:length(x)-1]

fig,(ax1,ax2) = subplots(2,1,figsize=(5,2.2),sharex=true)

for i in 1:length(x)
    ax1.scatter(x[i],0,20,color="C$(i-1)",edgecolor="k",zorder=10)
end

ax1.plot([0,xint[1]],[0,0],"C0")
ax1.plot([xint[1],xint[2]],[0,0],"C1")
ax1.plot([xint[2],3],[0,0],"C2")
ax1.set_yticks([])
ax1.set_frame_on(false)
ax1.set_title("Round nearest",loc="left")

ax1.plot([1.2,1.2],[-0.2,0.2],"k--",lw=0.5)
ax1.text(1.22,-0.2,L"x is round to $x_2$")

ax2.plot([-0.5,0,x[1]],[0,1,0],"C5")
ax2.plot([0,x[1],x[2]],[0,1,0],"C0")
ax2.plot([x[1],x[2],x[3]],[0,1,0],"C1")
ax2.plot([x[2],x[3],4],[0,1,0],"C2")
ax2.plot([x[3],4,5],[0,1,0],"C4")

for i in 1:length(x)
    ax2.scatter(x[i],1,20,color="C$(i-1)",edgecolor="k")
end

ax2.plot([1.2,1.2],[0,1],"k--",lw=0.5)
ax2.text(1.18,-0.3,L"x = ")
ax2.text(1.31,-0.15,L"$x_2$ at 80%")
ax2.text(1.31,-0.45,L"$x_3$ at 20% chance.")

ax2.set_xlim(x[1]-0.2,x[3]+0.2)
ax2.set_yticks([0,1])
ax2.set_yticklabels([L"0\%",L"100\%"])
ax2.set_xticks(x)
ax2.set_xticklabels([L"$x_1$",L"$x_2$",L"$x_3$"])
ax2.set_frame_on(false)
ax2.set_title("Stochastic rounding",loc="left")

ax1.set_title("a",loc="right",fontweight="bold")
ax2.set_title("b",loc="right",fontweight="bold")

tight_layout()
savefig("figs/schematic.pdf")
savefig("figs/schematic.png",dpi=200)
close(fig)
