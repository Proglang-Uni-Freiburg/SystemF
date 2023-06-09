module Tagless where

open import Level
open import Data.Fin
open import Data.Nat
open import Data.String
open import Data.List
open import Data.Vec

open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; trans; cong; cong₂; subst; resp₂)

-- syntax

Ident = String

variable n : ℕ

lof : ℕ → Level
lof ℕ.zero = Level.zero
lof (ℕ.suc n) = Level.suc (lof n)

module try2 where

  open import Data.Unit

  -- level environments
  LEnv = List ℕ
  variable Δ Δ₁ Δ₂ : LEnv

  data _∈_ : ℕ → LEnv → Set where
    here  : ∀ {l ls} → l ∈ (l ∷ ls)
    there : ∀ {l l′ ls} → l ∈ ls → l ∈ (l′ ∷ ls)

  data Type (Δ : LEnv) : Set where
    `_ : n ∈ Δ → Type Δ
    _⇒_ : Type Δ → Type Δ → Type Δ
    `∀α_,_ : (lev : ℕ) → Type (lev ∷ Δ) → Type Δ
    𝟙 : Type Δ

  -- level of type according to Leivant'91
  level : Type Δ → Level
  level (`_ {lev} x) = lof lev
  level (T₁ ⇒ T₂) = level T₁ Level.⊔ level T₂
  level (`∀α q , T) = Level.suc (lof q) Level.⊔ level T
  level 𝟙 = Level.zero

  -- environment mapping type variables to Agda types
  Env* : LEnv → Setω
  Env* Δ = ∀ {l} → l ∈ Δ → Set (lof l)

  extend-η : ∀ {l} {Δ : LEnv} → Set (lof l) → Env* Δ → Env* (l ∷ Δ)
  extend-η α η here = α
  extend-η α η (there x) = η x

  -- the meaning of a stratified type in terms of Agda universes
  ⟦_⟧ : (T : Type Δ) → Env* Δ → Set (level T)
  ⟦ ` x ⟧ η = η x
  ⟦ T₁ ⇒ T₂ ⟧ η = ⟦ T₁ ⟧ η → ⟦ T₂ ⟧ η
  ⟦ `∀α lev , T ⟧ η = (α : Set (lof lev)) → ⟦ T ⟧ (extend-η α η)
  ⟦ 𝟙 ⟧ η = ⊤

  -- renaming on types
  Ren : LEnv → LEnv → Set
  Ren Δ₁ Δ₂ = ∀ n → n ∈ Δ₁ → n ∈ Δ₂

  wkᵣ : Ren Δ (n ∷ Δ)
  wkᵣ _ = there

  extᵣ : Ren Δ₁ Δ₂ → (n : ℕ) → Ren (n ∷ Δ₁) (n ∷ Δ₂)
  extᵣ ρ _ _ here = here
  extᵣ ρ _ _ (there x) = there (ρ _ x)

  renT : Ren Δ₁ Δ₂ → (Type Δ₁ → Type Δ₂)
  renT ρ (`_ {n} x) = ` ρ n x
  renT ρ (T₁ ⇒ T₂) = renT ρ T₁ ⇒ renT ρ T₂
  renT ρ (`∀α lev , T) = `∀α lev , renT (extᵣ ρ lev) T
  renT ρ 𝟙 = 𝟙 

  wkT : Type Δ → Type (n ∷ Δ)
  wkT = renT wkᵣ 

  -- substitution on types
  Sub : LEnv → LEnv → Set
  Sub Δ₁ Δ₂ = ∀ n → n ∈ Δ₁ → Type Δ₂

  idₛ : Sub Δ Δ
  idₛ _ = `_

  extₛ : Sub Δ₁ Δ₂ → (n : ℕ) → Sub (n ∷ Δ₁) (n ∷ Δ₂)
  extₛ σ _ _ here = ` here
  extₛ σ _ _ (there x) = wkT (σ _ x)

  subT : Sub Δ₁ Δ₂ → (Type Δ₁ → Type Δ₂)
  subT σ (`_ {n} x) = σ n x
  subT σ (T₁ ⇒ T₂) = subT σ T₁ ⇒ subT σ T₂
  subT σ (`∀α lev , T) = `∀α lev , subT (extₛ σ lev) T
  subT σ 𝟙 = 𝟙 

  singleₛ : Sub Δ₁ Δ₂ → Type Δ₂ → Sub (n ∷ Δ₁) Δ₂
  singleₛ σ T' _ here = T'
  singleₛ σ T' _ (there x) = σ _ x

  _[_]T : Type (n ∷ Δ) → Type Δ → Type Δ
  _[_]T {n} T T' = subT (singleₛ idₛ T') T

  -- type environments
  data TEnv : LEnv → Set where
    ∅    : TEnv []
    _◁_  : Type Δ → TEnv Δ → TEnv Δ
    _◁*_ : (l : ℕ) → TEnv Δ → TEnv (l ∷ Δ)
  
  data inn : ∀ {Δ} → Type Δ → TEnv Δ → Set where
    here  : ∀ {T Γ} → inn {Δ} T (T ◁ Γ)
    there : ∀ {T T′ Γ} → inn {Δ} T Γ → inn {Δ} T (T′ ◁ Γ)
    tskip : ∀ {T l Γ} → inn {Δ} T Γ → inn (wkT T) (l ◁* Γ)

  data Expr : (Δ : LEnv) → TEnv Δ → Type Δ → Set where
    `_    : ∀ {T : Type Δ} {Γ : TEnv Δ} → inn T Γ → Expr Δ Γ T
    ƛ_    : ∀ {T T′ : Type Δ} {Γ : TEnv Δ} → Expr Δ (T ◁ Γ) T′ → Expr Δ Γ (T ⇒ T′)
    _·_   : ∀ {T T′ : Type Δ} {Γ : TEnv Δ} → Expr Δ Γ (T ⇒ T′) → Expr Δ Γ T → Expr Δ Γ T′
    Λα_⇒_ : ∀ {Γ : TEnv Δ} → (l : ℕ) → {T : Type (l ∷ Δ)} → Expr (l ∷ Δ) (l ◁* Γ) T → Expr Δ Γ (`∀α l , T)
    _∙_   : ∀ {l : ℕ} {T : Type (l ∷ Δ)} {Γ : TEnv Δ} → Expr Δ Γ (`∀α l , T) → (T′ : Type Δ) → level T′ ≡ lof l → Expr Δ Γ (T [ T′ ]T)
    
  Env : (Δ : LEnv) → TEnv Δ → Env* Δ → Setω
  Env Δ Γ η = ∀ {T : Type Δ} → (x : inn T Γ) → ⟦ T ⟧ η

  extend-γ : ∀ {Δ : LEnv} {Γ : TEnv Δ} {T : Type Δ} {η : Env* Δ} → ⟦ T ⟧ η → Env Δ Γ η → Env Δ (T ◁ Γ) η
  extend-γ x γ here = x
  extend-γ _ γ (there x) = γ x

  extend-γ-by-ℓ : ∀ {Δ : LEnv} {Γ : TEnv Δ} {η : Env* Δ} (l : ℕ) {η′ : Env* (l ∷ Δ)} → Env Δ Γ η → Env (l ∷ Δ) (l ◁* Γ) η′
  extend-γ-by-ℓ l γ (tskip x) = {! λ _ → γ x !}

  E⟦_⟧ : ∀ {T : Type Δ}{Γ : TEnv Δ} → Expr Δ Γ T → (η : Env* Δ) → Env Δ Γ η → ⟦ T ⟧ η
  E⟦ ` x ⟧ η γ = γ x
  E⟦ ƛ e ⟧ η γ x = E⟦ e ⟧ η (extend-γ x γ)
  E⟦ e₁ · e₂ ⟧ η γ = E⟦ e₁ ⟧ η γ (E⟦ e₂ ⟧ η γ)
  E⟦ Λα l ⇒ e ⟧ η γ α = E⟦ e ⟧ (extend-η {l} α η) (extend-γ-by-ℓ l γ)
  E⟦ (e ∙ T′) ≡l ⟧ η γ with E⟦ e ⟧ η γ | ⟦ T′ ⟧ η 
  E⟦ (e ∙ T′) ≡l ⟧ η γ | e₁ | T′₁ rewrite ≡l with e₁ T′₁
  E⟦ (e ∙ T′) ≡l ⟧ η γ | e₁ | T′₁ | v  = {! v !}
 
