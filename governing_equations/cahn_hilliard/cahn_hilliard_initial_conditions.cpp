#include "cahn_hilliard_initial_conditions.hpp"
#include "cahn_hilliard_parameters.hpp"
#include "governing_equations/time_integrable_rhs.hpp"
#include "data_structures/solution_state.hpp"

#include <random>


CahnHilliardInitialConditions::CahnHilliardInitialConditions(CahnHilliardParameters& params)
    : m_(params.m()), min_(params.initialMin()), max_(params.initialMax()), seed_(params.initialSeed())
{
}


void
CahnHilliardInitialConditions::set(const TimeIntegrableRHS& rhs, SolutionState& state) const
{
  // Seeded from --initial_condition_seed, whose default of 2 is the constant used before the option existed.
  std::mt19937                            gen(seed_);
  std::uniform_real_distribution<real_wp> dist(min_, max_);
  Logger::get().InfoMessage("RNG initial conditions drawn with seed " + std::to_string(seed_) + ".");


  auto idx = read_access_host(rhs.interiorIndices());
  auto c   = write_access_host(state.getVec(0));

  /**
   * Would prefer to use a maDGForAllHost here but std::uniform_real_distribution lambda copy
   * has to be mutable.
   *
   * Additionally do a Kahan summation to compute the average which will differ from m_ due to RNG.
   */
  double sum = 0;
  double tmp = 0;
  for (int i = 0; i < idx.size(); ++i) {
    c[idx[i]] = m_ + dist(gen);
    const double y = c[idx[i]] - tmp;
    const double t = sum + y;
    tmp = (t-sum) -y;
    sum = t;
  }
  const double mean = sum / double(idx.size());
  Logger::get().InfoMessage("RNG initial conditions have mean " + std::to_string(mean) + ", renormalizing.");

  for (int i = 0; i < idx.size(); ++i) {
    c[idx[i]] -= (mean-m_);
  }
}