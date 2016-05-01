
# Handling the powerlet selection

For finding the set of relevant powerlets in @Elhamifar2015 they also add a
smoothing term, but in @Abassi2015 they state that for low resolution
disaggregation that doesn't make sense and they drop it. So the final
formulation for finding relevant powerlets is:

$$
\mathrm{minimize}\quad tr(D^TZ) + \gamma ||Z||_{\infty,1} \\
s.t. \quad 1^TZ=1^T,\quad Z\geq0
$$


where $Z \in R^{n\times n}$ with $n=T-w+1$ in which each element $z_{ij}$
represents how much snippet *i* represents snippet *j*. The term
$||Z||_{\infty,1} = \sum_{i=1}^n ||z_{i,\cdot}||_\infty$ is aimed at counting
the number of non-zero rows. The optimization is just a linear problem
optimization with equality constraints that just enforce that variables are
probabilities and include an sparsity term for favoring few powerlets.

Let's start breaking down this formulation into something an solver can understand.

First $\mathrm{minimize}\; \gamma||Z||_{\infty,1}$ is translated into:

$$
\mathrm{minimize}\quad  \sum_{i}^n ||z_{i,\cdot}||_\infty
$$

that in turn is translated using slack variables into:

$$
\begin{aligned}
& \mathrm{minimize} &&  \sum_{i}^n t_i \\
  & \mathrm{subject to} && -t_i \leq z_{ij} \leq t_i \\
  &&& t_i \geq 0
\end{aligned}
$$

> **NOTE** After the translation, the minimization problem looks like we were e
> minimizing the $||\cdot||_1$ instead of the $||\cdot||_\infty$. That is
> because of the special notation of $||\cdot||_{\infty,1}||$ authors use in
> the paper and by the fact that there was a summation in the formulation.

[unrolling  the $tr()$
operator](https://en.wikipedia.org/wiki/Trace_(linear_algebra)#Trace_of_a_product)
we get $tr(D^TZ) = \sum_{i,j}^n d_{ij}z_{ij}$  so when we put the problem
together we have:

$$
\begin{aligned}
& \mathrm{minimize} && \sum_i^N\sum_j^N d_{ij}z_{ij}+\gamma \sum_i^N t_i \\
& \mathrm{subject to} && \sum_i^N z_{ij} = 1 \\
&&& z_{ij} - t_i \leq 0 \\
&&& z_{ij} \geq 0 \quad t_i \geq 0 \quad \forall i,j \in N
\end{aligned}
$$

> **NOTE** Since D is symmetric, transposing D in the expression is just for
> helping in the implementation because $tr(D^TZ)$ then becomes an element wise
> multiplication and the summation of all the elements in the resulting matrix

With this we perform cross validation for finding a $\gamma$ that gives us around 20 powerlets per signal.

> **NOTE** Look at the optimization function. Because of the constraints, all
variables will be in $[0,1]$ and the minimization function will have 2 parts,
the part governed by the $t_i$ controlling sparsity of the solution and the side
of the variables itself. If: $$\gamma N \geq \sum_i^N\sum_j^N d_{ij}$$ the
sparsity term will dominate the solution and the solution will bias towards
distributing evenly the activation of variables. So controlling the value of
$\gamma$ in the range of $$\gamma \in \left[0,\frac{1}{N}\sum_i^N\sum_j^N
d_{ij}\right]$$ controls the shape of the solution, with 0 being the sparsest
solution possible.

# Translating to an optimization problem the main algorithm

In @Abassi2015 they propose 5 modifications for the low resolution scenario.
They go for the first 3 in all cases and test turning on/off modifications 4 and
5 described in Section 5.1.3 of the paper. They report that best results are
with combination of *prior probabilities*  and *non overlapping snippets*, so
we'll follow here same path.

So given the formulation, and the obtained characterization matrix $Z$ we
construct the powerlet dictionary $B \in R^{w\times N}$. Then for the disaggregation problem we
have to solve:

$$
\begin{aligned}
& \mathrm{minimize} && \sum_{t=1}^T \left( ||y(t)-Bc(t)||_1 + \lambda(\log p)^Tc(t)+ \lambda\eta\frac{1}{2}\sum_{(i,j) \in A}((e^i-e^j)^Tc(t))^2  \right) \\
&\mathrm{subject to} && 1^Tc_d(t) = 1,\; d=1,\dots,D \\
&&& c(t)\in \left\{0,1\right\}^N
\end{aligned}
$$

where $p$ is a vector containing the probability of activation of a given
powerlet for all devices. The probability for powerlet $i$ is calculated as $p_i
= \sum_{j=1}^n z_{ij}$ and if we compose all probabilities in a vector $p^{(d)}$
then we get that $p=  p^{(1)}p^{(2)}\dots p^{(D)}  $. This element is going to be
constant since are values provided from the previous step.

Modification 5 means shrinking the number of variables to $\lfloor \frac{T}{w}
\rfloor$ points in the time series in order to avoid overlapping snippets. So we
are going to solve for variables $c(t)$ with $t \in  1,1+w,1+2w, \dots $. In
order to avoid confusion I'm going to introduce a new index variable called $s$
that represents those points in time $ s:  1,1+w,1+2w,\dots  \rightarrow
1,2,3,\dots  $ so we are going to be minimizing over variables $C \in R^{N
\times \lfloor \frac{T}{w}\rfloor}$

For the $l_1$ norm, the first term in a minimization problem translates into:

$$
\begin{aligned}
& \mathrm{minimize} && 1^Tr_s\\
& \mathrm{subject to} && -r_s \leq y(t)-Bc_s \leq r_s \quad r_s \in R^{w}
\end{aligned}
$$

Second term is translated as-is.

Let's focus on the third term. In the original formulation, terms $e^d \in
\left\{0,1\right\}^{N_d}$ are de device-powerlet indicator being $e_i^d=1$ when
powerlet $i$ was active por device *d*. But this presents some inconveniences.
First our constraint $1^Tc_d(t)=1$ forces us to have always a powerlet active
and thus make the term $(e^i - e^j)^Tc(t)$ always 0 for devices in *A*. We could
spare this restriction by using $1^Tc(t) \leq 1$ but then we loose the weighting
of the probability of powerlets related to stand-by, since those were filtered
previously as they are not needed if we use the *less or equal* operator. So a
way to circumvent this restriction could be constructing $e^d$ as $e_i^d = 1$ if
powerlet *i* belongs to device *d* and powerlet *i* satisfies $||y_i|| >
\epsilon w$ where $\epsilon = 1$. This last condition makes the $e_i^d$ terms
active only when the device is in the active regime of consumption.

Note that vector $e^d \in R^N$ is bigger
than should be as indicator since for all devices there will be elements in the
indicator $e^d$ that will be always 0. Composing indicator vectors for all the
devices under study we get matrix $E= [ e^1 , \dots ,e^D ]$.

This third term is of the form $((e^i-e^j)^Tc_s)^2$ and at first I was afraid
our linear problem could become a convex one, but since $(e^i-e^j)$ can only
take values in $\left\{-1,0,1\right\}$ and multiplying by $c_s$ won't change
that fact. Going $(\cdot)^2$ thus, is the same thing as taking absolute value
$|x|$. Since, negative values will only appear in the constant term of the
expression we could just translate the third term into:

$$
|e^i-e^j|
$$

where $|x|$ returns a vector with the absolute value of each element in the
original vector.

The set $A \in D\times D$ is the set of co-occurring devices. Both in
@Elhamifar2015 and @Abassi2015 they only use the kitchen devices as pairs in $A$
because they report higher performance. In both articles they refer to this
third term as being like $(\cdot)^2$. But then this convert the problem into

> **FUTURE WORK** study the effect of instead of restricting co-occurrence to a
> set of devices, add a correlation matrix to the optimization problem

The final formulation of the problem is thus a **mixed integer programming**
problem.

$$
\begin{aligned}
& \mathrm{minimize} &&
   \sum_{s=1}^{\lfloor \frac{T}{w} \rfloor} \left( 1^Tr_s
       + \lambda(\log p)^Tc_s
       + \lambda\eta\frac{1}{2}\sum_{(i,j) \in A}|e^i-e^j|^Tc_s  \right) \\
&\mathrm{subject to} && 1^Tc_s^d = 1,\; d=1,\dots,D \\
&&& -r_s \leq y(t)-Bc_s \leq r_s \quad s=1,\dots, \lfloor\frac{T}{w}\rfloor,\quad t=1,1+w,1+2w,...\;,\quad r_s\in R^{w} \\
 &&& c_s\in \left\{0,1\right\}^N
\end{aligned}
$$


## Translating the mathematical formulation into code

Now we have the mathematical problem posed in a more digestible formulation for
a computer program. Now it is time to translate that into the DSL or API that
the library solving this problem is giving us. For the problem at hand we will
use [MOSEK](https://www.mosek.com/) in Python. MOSEK because it was used in all
the papers and reports significantly performance over open source alternatives
like [GPLK](https://www.gnu.org/software/glpk/), and Python because then we
could interface easily with [NILMTK](http://nilmtk.github.io/).

Testing the implementation of a machine learning algorithm implementation is
difficult because it is difficult to create assertions on the results. You have
some numbers in and you get some numbers out and you don't know for sure whether
the misalignment between training and testing is because the algorithm or
because you failed in the implementation. Here we are going to approach the
problem step by step trying to learn how to test complex implementations and
learning some tricks in the process.

### Tests to implement

1. Formulation for $tr(D^TZ)$ must equal $tr(ZD^T)$ because of properties of
$tr()$ 

# Lessons learned

1. For complex algorithms were you cannot come with an easy test from the top of your head, setup a simple example and make to competing alternatives/implementations provide you with the answer. If they diverge investigate the mismatch.
1. Stay away of results too uniform. My first implementation although correct had the $gamma$ to high and biased the solution towards even activations of z giving the same value for all the variables. This was masking the fact that indexes were being reported in wrong order. So always aim for expected solution diversity.

# TODO

After talking with Jorge about some concerns he has these are my findings.

1. Comprobar si la fórmula (4) representa probabilities. NO, it doesn't represent probabilities. Summing across rows gives you how much a powerlet was used in the representations, but for this number to be fair across devices, within a given device, those values must be converted to percentages. So Jorge was right.
1. Repasar el tema de las activaciones de los $e_t$. Jorge had concerns about the term $(e^i - e^j)^Tc(t)$ and he was right. It is always 0 as formulated in the Swedish paper. Look at the note discussing how to overcome the problem.

# References
