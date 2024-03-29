module StratF.Types where

open import Level
open import Data.List using (List; []; _∷_)
open import Data.Nat using (ℕ)

variable l l′ l₁ l₂ l₃ : Level

--! TF >

-- level environments

--! LEnv
LEnv = List Level

variable Δ Δ₁ Δ₂ Δ₃ : LEnv

-- type variables

data _∈_ : Level → LEnv → Set where
  here   : l ∈ (l ∷ Δ)
  there  : l ∈ Δ → l ∈ (l′ ∷ Δ)

-- types

--! Type
data Type Δ : Level → Set where
  `ℕ      : Type Δ zero
  _⇒_     : Type Δ l → Type Δ l′ → Type Δ (l ⊔ l′)
  `_      : l ∈ Δ → Type Δ l
  `∀α_,_  : ∀ l → Type (l ∷ Δ) l′ → Type Δ (suc l ⊔ l′)

variable T T′ T₁ T₂ : Type Δ l

-- level of type according to Leivant'91
level : Type Δ l → Level
level {l = l} T = l

-- semantic environments (mapping level l to an element of Set l)

--! TEnv
data Env* : LEnv → Setω where
  []   : Env* []
  _∷_  : Set l → Env* Δ → Env* (l ∷ Δ)

variable
  η η₁ η₂ : Env* Δ  

lookup : l ∈ Δ → Env* Δ → Set l
lookup here      (x ∷ _) = x
lookup (there x) (_ ∷ η) = lookup x η

apply-env : Env* Δ → l ∈ Δ → Set l
apply-env η x = lookup x η

-- the meaning of a stratified type in terms of Agda universes

--! TSem
⟦_⟧ : (T : Type Δ l) → Env* Δ → Set l
⟦ `ℕ         ⟧ η = ℕ
⟦ T₁ ⇒ T₂    ⟧ η = ⟦ T₁ ⟧ η → ⟦ T₂ ⟧ η
⟦ ` α        ⟧ η = lookup α η  
⟦ `∀α l , T  ⟧ η = (α : Set l) → ⟦ T ⟧ (α ∷ η)
