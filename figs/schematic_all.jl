using PyPlot
using Statistics

Statistics.mean(x::Real,y::Real) = (x+y)/2

x = [0.5,1.0,2.0]
xint = [mean(x[i],x[i+1]) for i in 1:length(x)-1]

fig,(ax1,ax2,ax3,ax4,ax5) = subplots(5,1,figsize=(5,5),sharex=true)
axs = [ax1,ax2,ax3,ax4,ax5]

# BITSHAVE
for i in 1:length(x)
    ax1.scatter(x[i],0,20,color="C$(i-1)",edgecolor="k",zorder=10)
end

ax1.plot([0,x[1]],[0,0],"C5")
ax1.plot([x[1],x[2]],[0,0],"C0")
ax1.plot([x[2],x[3]],[0,0],"C1")
ax1.plot([x[3],3],[0,0],"C2")
ax1.set_yticks([])
ax1.set_title("Bitshave (round-to-zero)",loc="left")

ax1.plot([1.2,1.2],[-0.2,0.2],"k--",lw=0.5)
ax1.text(1.22,-0.2,L"x is round to $x_2$")

# BITSET
for i in 1:length(x)-1
    ax2.scatter(x[i+1]-0.02,0,20,color="C$(i-1)",edgecolor="k",zorder=10)
end

ax2.plot([0,x[1]],[0,0],"C5")
ax2.plot([x[1],x[2]],[0,0],"C0")
ax2.plot([x[2],x[3]],[0,0],"C1")
ax2.plot([x[3],3],[0,0],"C2")
ax2.set_yticks([])
ax2.set_title("Bitset (round-away-from-zero)",loc="left")

ax2.plot([1.2,1.2],[-0.2,0.2],"k--",lw=0.5)
ax2.text(1.22,-0.2,L"x is round to $x_3^-$")

# HALFSHAVE
for i in 1:length(xint)
    ax3.scatter(xint[i],0,20,color="C$(i-1)",edgecolor="k",zorder=10)
end

ax3.plot([0,x[1]],[0,0],"C5")
ax3.plot([x[1],x[2]],[0,0],"C0")
ax3.plot([x[2],x[3]],[0,0],"C1")
ax3.plot([x[3],3],[0,0],"C2")
ax3.set_yticks([])
ax3.set_title("Halfshave",loc="left")

ax3.plot([1.2,1.2],[-0.2,0.2],"k--",lw=0.5)
ax3.text(1.22,-0.2,L"x is round to $x_2^*$")

# ROUND NEAREST
for i in 1:length(x)
    ax4.scatter(x[i],0,20,color="C$(i-1)",edgecolor="k",zorder=10)
end

ax4.plot([0,xint[1]],[0,0],"C0")
ax4.plot([xint[1],xint[2]],[0,0],"C1")
ax4.plot([xint[2],3],[0,0],"C2")
ax4.set_yticks([])
ax4.set_title("Round-to-nearest",loc="left")

ax4.plot([1.2,1.2],[-0.2,0.2],"k--",lw=0.5)
ax4.text(1.22,-0.2,L"x is round to $x_2$")

# STOCHASTIC ROUNDING
ax5.plot([-0.5,0,x[1]],[0,1,0],"C5")
ax5.plot([0,x[1],x[2]],[0,1,0],"C0")
ax5.plot([x[1],x[2],x[3]],[0,1,0],"C1")
ax5.plot([x[2],x[3],4],[0,1,0],"C2")
ax5.plot([x[3],4,5],[0,1,0],"C4")

for i in 1:length(x)
    ax5.scatter(x[i],1,20,color="C$(i-1)",edgecolor="k",zorder=10)
end

ax5.plot([1.2,1.2],[0,1],"k--",lw=0.5)
ax5.text(1.18,-0.3,L"x = ")
ax5.text(1.31,-0.15,L"$x_2$ at 80%")
ax5.text(1.31,-0.45,L"$x_3$ at 20% chance.")

ax5.set_xlim(x[1]-0.2,x[3]+0.2)
ax5.set_yticks([0,1])
ax5.set_ylim([-0.1,1.1])
ax5.set_yticklabels([L"0\%",L"100\%"])
ax5.set_xticks(x)
ax5.set_xticklabels([L"$x_1$",L"$x_2$",L"$x_3$"])
ax5.set_title("Stochastic rounding",loc="left")

for (iax,ax) in enumerate(axs)
    ax.set_title(string(Char(iax+96)),loc="right",fontweight="bold")
    ax.set_frame_on(false)
end

tight_layout()
savefig("figs/schematic_all.pdf")
savefig("figs/schematic_all.png",dpi=200)
