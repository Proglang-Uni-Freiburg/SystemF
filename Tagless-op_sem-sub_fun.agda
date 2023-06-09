module Tagless-op_sem-sub_fun where

open import Level
open import Data.Product using (_×_; Σ-syntax; ∃-syntax; _,_)
open import Data.Fin using (Fin) renaming (zero to fzero; suc to fsuc)
open import Data.List using (List; []; _∷_; _++_; length; lookup; tabulate)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Function using (_∘_; id)
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; trans; cong; cong₂; subst; subst₂; resp₂; cong-app; icong; module ≡-Reasoning)
open import Axiom.Extensionality.Propositional using (∀-extensionality; Extensionality)
open ≡-Reasoning

variable l l′ l₁ l₂ l₃ : Level

----------------------------------------------------------------------

postulate
  fun-ext : ∀{a b} → Extensionality a b

fun-ext₂ : ∀ {A₁ : Set l₁} {A₂ : A₁ → Set l₂} {B : (x : A₁) → A₂ x → Set l₃}
             {f g : (x : A₁) → (y : A₂ x) → B x y} →
    (∀ (x : A₁) (y : A₂ x) → f x y ≡ g x y) →
    f ≡ g
fun-ext₂ h = fun-ext λ x → fun-ext λ y → h x y

dep-ext : ∀ {a b}{A : Set a}{F G : (α : A) → Set b}
    → (∀ (α : A) → F α ≡ G α)
    → ((α : A) → F α) ≡ ((α : A) → G α) 
dep-ext = ∀-extensionality fun-ext _ _

-- equality for Setω

data _≡ω_ {A : Setω} (x : A) : A → Setω where
  refl : x ≡ω x

congωl : ∀ {b} {A : Setω} {B : Set b} (f : A → B) {x y : A} → x ≡ω y → f x ≡ f y
congωl f refl = refl

conglω : ∀ {a} {A : Set a} {B : Setω} (f : A → B) {x y : A} → x ≡ y → f x ≡ω f y
conglω f refl = refl

congωω : ∀ {A : Setω} {B : Setω} (f : A → B) {x y : A} → x ≡ω y → f x ≡ω f y
congωω f refl = refl

transω : ∀ {A : Setω} {x y z : A} → x ≡ω y → y ≡ω z → x ≡ω z
transω refl refl = refl

----------------------------------------------------------------------

-- level environments

{- data LEnv′ (l : Level) : Set l where 
  []  : LEnv′ l
  _∷_[_] : (l′ : Level) → LEnv′ l → l′ ⊔ l ≡ l → LEnv′ l -}
   
LEnv = List Level
variable Δ Δ₁ Δ₂ Δ₃ : LEnv

-- type variables

data _∈_ : Level → LEnv → Set where
  here  : l ∈ (l ∷ Δ)
  there : l ∈ Δ → l ∈ (l′ ∷ Δ)

-- types

data Type Δ : Level → Set where
  `_     : l ∈ Δ → Type Δ l
  _⇒_    : Type Δ l → Type Δ l′ → Type Δ (l ⊔ l′)
  `∀α_,_ : ∀ l → Type (l ∷ Δ) l′ → Type Δ (suc l ⊔ l′)
  𝟙      : Type Δ zero

variable T T′ T₁ T₂ : Type Δ l


-- level of type according to Leivant'91
level : Type Δ l → Level
level {l = l} T = l

-- semantic environments (mapping level l to an element of Set l)

{- data Env*′ (l : Level) : LEnv′ l → Set l where
  []  : Env*′ l []
  _∷_[_] : ∀{Δ : LEnv′ l} → Set l′ → Env*′ l Δ → (eq : l ⊔ l′ ≡ l) → Env*′ l (l′ ∷ Δ [ eq ]) -}

data Env* : LEnv → Setω where
  []  : Env* []
  _∷_ : Set l → Env* Δ → Env* (l ∷ Δ)

apply-env : Env* Δ → l ∈ Δ → Set l
apply-env [] ()
apply-env (x ∷ _) here = x
apply-env (_ ∷ η) (there x) = apply-env η x

-- the meaning of a stratified type in terms of Agda universes

⟦_⟧ : (T : Type Δ l) → Env* Δ → Set l
⟦ ` x ⟧ η = apply-env η x
⟦ T₁ ⇒ T₂ ⟧ η = ⟦ T₁ ⟧ η → ⟦ T₂ ⟧ η
⟦ `∀α l , T ⟧ η = (α : Set l) → ⟦ T ⟧ (α ∷ η)
⟦ 𝟙 ⟧ η = ⊤

-- renaming on types

TRen : LEnv → LEnv → Set
TRen Δ₁ Δ₂ = ∀ l → l ∈ Δ₁ → l ∈ Δ₂

variable 
  ρ ρ₁ ρ₂ : TRen Δ₁ Δ₂

Tidᵣ : TRen Δ Δ
Tidᵣ _ = id

Tdropᵣ : TRen (l ∷ Δ₁) Δ₂ → TRen Δ₁ Δ₂
Tdropᵣ ρ _ x = ρ _ (there x)

Twkᵣ : TRen Δ₁ Δ₂ → TRen Δ₁ (l ∷ Δ₂)
Twkᵣ ρ _ x = there (ρ _ x) 

Tliftᵣ : TRen Δ₁ Δ₂ → (l : Level) → TRen (l ∷ Δ₁) (l ∷ Δ₂)
Tliftᵣ ρ _ _ here = here
Tliftᵣ ρ _ _ (there x) = there (ρ _ x)

Tren : TRen Δ₁ Δ₂ → (Type Δ₁ l → Type Δ₂ l)
Tren ρ (` x) = ` ρ _ x
Tren ρ (T₁ ⇒ T₂) = Tren ρ T₁ ⇒ Tren ρ T₂
Tren ρ (`∀α l , T) = `∀α l , Tren (Tliftᵣ ρ l) T
Tren ρ 𝟙 = 𝟙 

Twk : Type Δ l′ → Type (l ∷ Δ) l′
Twk = Tren (Twkᵣ Tidᵣ)

-- the action of renaming on semantic environments

TRen* : (ρ : TRen Δ₁ Δ₂) → (η₁ : Env* Δ₁) → (η₂ : Env* Δ₂) → Setω
TRen* {Δ₁} ρ η₁ η₂ = ∀ {l : Level} → (x : l ∈ Δ₁) → apply-env η₂ (ρ _ x) ≡ apply-env η₁ x

wkᵣ∈Ren* : ∀ (η : Env* Δ) (⟦α⟧ : Set l) → TRen* (Twkᵣ {Δ₁ = Δ}{l = l} Tidᵣ) η (⟦α⟧ ∷ η)
wkᵣ∈Ren* η ⟦α⟧ x = refl

Tren*-id : (η : Env* Δ) → TRen* (λ _ x → x) η η
Tren*-id η x = refl

Tren*-pop : (ρ : TRen (l ∷ Δ₁) Δ₂) (α : Set l) (η₁ : Env* Δ₁) (η₂ : Env* Δ₂) → TRen* ρ (α ∷ η₁) η₂ → TRen* (λ _ x → ρ _ (there x)) η₁ η₂
Tren*-pop ρ α η₁ η₂ Tren* x = Tren* (there x)

Tren*-ext : ∀ {ρ : TRen Δ₁ Δ₂}{η₁ : Env* Δ₁}{η₂ : Env* Δ₂} (α : Set l)
  → TRen* ρ η₁ η₂ → TRen* (Tliftᵣ ρ _) (α ∷ η₁) (α ∷ η₂)
Tren*-ext α Tren* here = refl
Tren*-ext α Tren* (there x) = Tren* x

Tren*-preserves-semantics : ∀ {ρ : TRen Δ₁ Δ₂}{η₁ : Env* Δ₁}{η₂ : Env* Δ₂}
  → (Tren* : TRen* ρ η₁ η₂) → (T : Type Δ₁ l) →  ⟦ Tren ρ T ⟧ η₂ ≡ ⟦ T ⟧ η₁
Tren*-preserves-semantics {ρ = ρ} {η₁} {η₂} Tren* (` x) = Tren* x
Tren*-preserves-semantics {ρ = ρ} {η₁} {η₂} Tren* (T₁ ⇒ T₂)
  rewrite Tren*-preserves-semantics {ρ = ρ} {η₁} {η₂} Tren* T₁
  | Tren*-preserves-semantics {ρ = ρ} {η₁} {η₂} Tren* T₂
  = refl
Tren*-preserves-semantics {ρ = ρ} {η₁} {η₂} Tren* (`∀α l , T) = dep-ext λ where 
  α → Tren*-preserves-semantics{ρ = Tliftᵣ ρ _}{α ∷ η₁}{α ∷ η₂} (Tren*-ext {ρ = ρ} α Tren*) T
Tren*-preserves-semantics Tren* 𝟙 = refl

-- substitution on types

TSub : LEnv → LEnv → Set
TSub Δ₁ Δ₂ = ∀ l → l ∈ Δ₁ → Type Δ₂ l

variable 
  σ σ₁ σ₂ : TSub Δ₁ Δ₂
 
Tidₛ : TSub Δ Δ
Tidₛ _ = `_

Tdropₛ : TSub (l ∷ Δ₁) Δ₂ → TSub Δ₁ Δ₂
Tdropₛ σ _ x = σ _ (there x)

Twkₛ : TSub Δ₁ Δ₂ → TSub Δ₁ (l ∷ Δ₂)
Twkₛ σ _ x = Twk (σ _ x)

Tliftₛ : TSub Δ₁ Δ₂ → (l : Level) → TSub (l ∷ Δ₁) (l ∷ Δ₂)
Tliftₛ σ _ _ here = ` here
Tliftₛ σ _ _ (there x) = Twk (σ _ x)

Tsub : TSub Δ₁ Δ₂ → Type Δ₁ l → Type Δ₂ l
Tsub σ (` x) = σ _ x
Tsub σ (T₁ ⇒ T₂) = Tsub σ T₁ ⇒ Tsub σ T₂
Tsub σ (`∀α l , T) = `∀α l , Tsub (Tliftₛ σ _) T
Tsub σ 𝟙 = 𝟙

Textₛ : TSub Δ₁ Δ₂ → Type Δ₂ l → TSub (l ∷ Δ₁) Δ₂
Textₛ σ T' _ here = T'
Textₛ σ T' _ (there x) = σ _ x

_[_]T : Type (l ∷ Δ) l′ → Type Δ l → Type Δ l′
_[_]T T T' = Tsub (Textₛ Tidₛ T') T


-- type environments

data TEnv : LEnv → Set where
  ∅    : TEnv []
  _◁_  : Type Δ l → TEnv Δ → TEnv Δ
  _◁*_ : (l : Level) → TEnv Δ → TEnv (l ∷ Δ)

variable Γ Γ₁ Γ₂ : TEnv Δ

data inn : Type Δ l → TEnv Δ → Set where
  here  : ∀ {T Γ} → inn {Δ}{l} T (T ◁ Γ)
  there : ∀ {T : Type Δ l}{T′ : Type Δ l′}{Γ} → inn {Δ}{l} T Γ → inn {Δ} T (T′ ◁ Γ)
  tskip : ∀ {T l Γ} → inn {Δ}{l′} T Γ → inn (Twk T) (l ◁* Γ)

data Expr (Δ : LEnv) (Γ : TEnv Δ) : Type Δ l → Set where
  `_   : ∀ {T : Type Δ l} → inn T Γ → Expr Δ Γ T
  ƛ_   : ∀ {T : Type Δ l}{T′ : Type Δ l′} → Expr Δ (T ◁ Γ) T′ → Expr Δ Γ (T ⇒ T′)
  _·_  : ∀ {T : Type Δ l}{T′ : Type Δ l′} → Expr Δ Γ (T ⇒ T′) → Expr Δ Γ T → Expr Δ Γ T′
  Λ_⇒_ : ∀ (l : Level) → {T : Type (l ∷ Δ) l′} → Expr (l ∷ Δ) (l ◁* Γ) T → Expr Δ Γ (`∀α l , T)
  _∙_  : ∀ {T : Type (l ∷ Δ) l′} → Expr Δ Γ (`∀α l , T) → (T′ : Type Δ l) → Expr Δ Γ (T [ T′ ]T)

variable e e₁ e₂ e₃ : Expr Δ Γ T

-- value environments

Env : (Δ : LEnv) → TEnv Δ → Env* Δ → Setω
Env Δ Γ η = ∀ {l}{T : Type Δ l} → (x : inn T Γ) → ⟦ T ⟧ η

extend : ∀ {T : Type Δ l}{Γ : TEnv Δ}{η : Env* Δ}
  → Env Δ Γ η → ⟦ T ⟧ η → Env Δ (T ◁ Γ) η
extend γ v here = v
extend γ v (there x) = γ x

extend-tskip : ∀ {Δ : LEnv}{Γ : TEnv Δ}{η : Env* Δ}{⟦α⟧ : Set l}
  → Env Δ Γ η → Env (l ∷ Δ) (l ◁* Γ) (⟦α⟧ ∷ η)
extend-tskip {η = η} {⟦α⟧ = ⟦α⟧} γ (tskip{T = T} x)
  rewrite Tren*-preserves-semantics {ρ = Twkᵣ Tidᵣ} {η} {⟦α⟧ ∷ η} (wkᵣ∈Ren* η ⟦α⟧) T
  = γ x 

subst-to-env* : (σ : TSub Δ₁ Δ₂) → (η₂ : Env* Δ₂) → Env* Δ₁
subst-to-env* {[]} σ η₂ = []
subst-to-env* {x ∷ Δ₁} σ η₂ = ⟦ σ _ here ⟧ η₂ ∷ subst-to-env* (Tdropₛ σ) η₂

subst-var-preserves : (x  : l ∈ Δ₁) (σ  : TSub Δ₁ Δ₂) (η₂ : Env* Δ₂) → ⟦ σ _ x ⟧ η₂ ≡ apply-env (subst-to-env* σ η₂) x
subst-var-preserves here σ η₂ = refl
subst-var-preserves (there x) σ η₂ = subst-var-preserves x (Tdropₛ σ) η₂

subst-to-env*-wk : (σ  : TSub Δ₁ Δ₂) → (α  : Set l) → (η₂ : Env* Δ₂) → subst-to-env* (Twkₛ σ) (α ∷ η₂) ≡ω subst-to-env* σ η₂
subst-to-env*-wk {Δ₁ = []} σ α η₂ = refl
subst-to-env*-wk {Δ₁ = l ∷ Δ₁} σ α η₂
  rewrite Tren*-preserves-semantics {ρ = Twkᵣ Tidᵣ}{η₂}{α ∷ η₂} (wkᵣ∈Ren* η₂ α) (σ _ here)
  = congωω (⟦ (σ _ here) ⟧ η₂ ∷_) (subst-to-env*-wk (Tdropₛ σ) α η₂) -- easier?


subst-to-env*-build : ∀ (ρ : TRen Δ₁ Δ₂) (η₁ : Env* Δ₁) (η₂ : Env* Δ₂) → TRen* ρ η₁ η₂
  → subst-to-env* (λ _ x → ` ρ _ x) η₂ ≡ω η₁
subst-to-env*-build ρ [] η₂ Tren* = refl
subst-to-env*-build {Δ₁ = _ ∷ Δ₁} ρ (α ∷ η₁) η₂ Tren* = 
  transω (congωω (λ H → apply-env η₂ (ρ _ here) ∷ H) (subst-to-env*-build (λ _ x → ρ _ (there x)) η₁ η₂ (Tren*-pop ρ α η₁ η₂ Tren*)))
         (conglω (_∷ η₁) (Tren* here))

subst-to-env*-id : (η : Env* Δ) → subst-to-env* Tidₛ η ≡ω η
subst-to-env*-id {Δ = Δ} η = subst-to-env*-build {Δ₁ = Δ} (λ _ x → x) η η (Tren*-id η)

subst-preserves-type : Setω
subst-preserves-type =
  ∀ {Δ₁ Δ₂}{l}{η₂ : Env* Δ₂}
  → (σ : TSub Δ₁ Δ₂) (T : Type Δ₁ l)
  → ⟦ Tsub σ T ⟧ η₂ ≡ ⟦ T ⟧ (subst-to-env* σ η₂)

subst-preserves : subst-preserves-type
subst-preserves {η₂ = η₂} σ (` x) = subst-var-preserves x σ η₂
subst-preserves {η₂ = η₂} σ (T₁ ⇒ T₂)
  rewrite subst-preserves{η₂ = η₂} σ T₁
  |  subst-preserves{η₂ = η₂} σ T₂ = refl
subst-preserves {η₂ = η₂} σ (`∀α l , T) =
  dep-ext (λ α →
    trans (subst-preserves {η₂ = α ∷ η₂} (Tliftₛ σ _) T)
          (congωl (λ H → ⟦ T ⟧ (α ∷ H)) (subst-to-env*-wk σ α η₂)))
subst-preserves σ 𝟙 = refl
 
Tsingle-subst-preserves : ∀ (η : Env* Δ) (T′ : Type Δ l) (T : Type (l ∷ Δ) l′) → 
  ⟦ T [ T′ ]T ⟧ η ≡ ⟦ T ⟧ (⟦ T′ ⟧ η ∷ η)
Tsingle-subst-preserves {Δ = Δ} {l = l}{l′ = l′} η T′ T =
  trans (subst-preserves (Textₛ Tidₛ T′) T)
        (congωl (λ H → ⟦ T ⟧ (⟦ T′ ⟧ η ∷ H)) (subst-to-env*-id η))

E⟦_⟧ : ∀ {T : Type Δ l}{Γ : TEnv Δ} → Expr Δ Γ T → (η : Env* Δ) → Env Δ Γ η → ⟦ T ⟧ η
E⟦ ` x ⟧ η γ = γ x
E⟦ ƛ_ e ⟧ η γ = λ v → E⟦ e ⟧ η (extend γ v)
E⟦ e₁ · e₂ ⟧ η γ = E⟦ e₁ ⟧ η γ (E⟦ e₂ ⟧ η γ)
E⟦ Λ l ⇒ e ⟧ η γ = λ ⟦α⟧ → E⟦ e ⟧ (⟦α⟧ ∷ η) (extend-tskip γ)
E⟦ _∙_ {T = T} e T′ ⟧ η γ rewrite Tsingle-subst-preserves η T′ T = E⟦ e ⟧ η γ (⟦ T′ ⟧ η)

-- type in expr substitution


-- composition of renamings and substituions

_σσ→σ_ : TSub Δ₁ Δ₂ → TSub Δ₂ Δ₃ → TSub Δ₁ Δ₃
(σ₁ σσ→σ σ₂) _ x = Tsub σ₂ (σ₁ _ x)

_ρρ→ρ_ : TRen Δ₁ Δ₂ → TRen Δ₂ Δ₃ → TRen Δ₁ Δ₃
(ρ₁ ρρ→ρ ρ₂) _ x = ρ₂ _ (ρ₁ _ x)

_ρσ→σ_ : TRen Δ₁ Δ₂ → TSub Δ₂ Δ₃ → TSub Δ₁ Δ₃
(ρ ρσ→σ σ) _ x = σ _ (ρ _ x)

_σρ→σ_ : TSub Δ₁ Δ₂ → TRen Δ₂ Δ₃ → TSub Δ₁ Δ₃
(σ σρ→σ ρ) _ x = Tren ρ (σ _ x)


-- interaction of renamings and substituions

sub↑-dist-ρσ→σ : ∀ l (ρ : TRen Δ₁ Δ₂) (σ : TSub Δ₂ Δ₃) →
  Tliftₛ (ρ ρσ→σ σ) _ ≡ Tliftᵣ ρ l ρσ→σ Tliftₛ σ _ 
sub↑-dist-ρσ→σ l ρ σ = fun-ext₂ λ where 
  _ here → refl
  _ (there x) → refl

mutual 
  assoc-sub↑-ren↑ : ∀ (T : Type (l ∷ Δ₁) l′) (ρ : TRen Δ₁ Δ₂) (σ : TSub Δ₂ Δ₃) →
    Tsub (Tliftₛ σ _) (Tren (Tliftᵣ ρ _) T) ≡ Tsub (Tliftₛ (ρ ρσ→σ σ) _) T
  assoc-sub↑-ren↑ T ρ σ = begin
      Tsub (Tliftₛ σ _) (Tren (Tliftᵣ ρ _) T) 
    ≡⟨ assoc-sub-ren T (Tliftᵣ ρ _) (Tliftₛ σ _) ⟩
      Tsub (Tliftᵣ ρ _ ρσ→σ Tliftₛ σ _) T
    ≡⟨ cong (λ σ → Tsub σ T) (sym (sub↑-dist-ρσ→σ _ ρ σ)) ⟩
      Tsub (Tliftₛ (ρ ρσ→σ σ) _) T
    ∎

  assoc-sub-ren : ∀ (T : Type Δ₁ l) (ρ : TRen Δ₁ Δ₂) (σ : TSub Δ₂ Δ₃) →
    Tsub σ (Tren ρ T) ≡ Tsub (ρ ρσ→σ σ) T
  assoc-sub-ren (` x) ρ σ = refl
  assoc-sub-ren (T₁ ⇒ T₂) ρ σ = cong₂ _⇒_ (assoc-sub-ren T₁ ρ σ) (assoc-sub-ren T₂ ρ σ)
  assoc-sub-ren (`∀α l , T) ρ σ = cong (`∀α l ,_) (assoc-sub↑-ren↑ T ρ σ)
  assoc-sub-ren 𝟙 ρ σ = refl

ren↑-dist-ρρ→ρ : ∀ l (ρ₁ : TRen Δ₁ Δ₂) (ρ₂ : TRen Δ₂ Δ₃) →
  Tliftᵣ (ρ₁ ρρ→ρ ρ₂) _ ≡ ((Tliftᵣ ρ₁ l) ρρ→ρ (Tliftᵣ ρ₂ _)) 
ren↑-dist-ρρ→ρ l ρ₁ ρ₂ = fun-ext₂ λ where 
  _ here → refl
  _ (there x) → refl

mutual 
  assoc-ren↑-ren↑ : ∀ (T : Type (l ∷ Δ₁) l′) (ρ₁ : TRen Δ₁ Δ₂) (ρ₂ : TRen Δ₂ Δ₃) →
    Tren (Tliftᵣ ρ₂ _) (Tren (Tliftᵣ ρ₁ _) T) ≡ Tren (Tliftᵣ (ρ₁ ρρ→ρ ρ₂) _) T
  assoc-ren↑-ren↑ {l = l} T ρ₁ ρ₂ =
      Tren (Tliftᵣ ρ₂ _) (Tren (Tliftᵣ ρ₁ _) T) 
    ≡⟨ assoc-ren-ren T (Tliftᵣ ρ₁ _) (Tliftᵣ ρ₂ _) ⟩
      Tren (Tliftᵣ ρ₁ _ ρρ→ρ Tliftᵣ ρ₂ _) T
    ≡⟨ cong (λ ρ → Tren ρ T) (sym (ren↑-dist-ρρ→ρ l ρ₁ ρ₂))  ⟩
      Tren (Tliftᵣ (ρ₁ ρρ→ρ ρ₂) _) T
    ∎

  assoc-ren-ren : ∀ (T : Type Δ₁ l) (ρ₁ : TRen Δ₁ Δ₂) (ρ₂ : TRen Δ₂ Δ₃) →
    Tren ρ₂ (Tren ρ₁ T) ≡ Tren (ρ₁ ρρ→ρ ρ₂) T
  assoc-ren-ren (` x) ρ₁ ρ₂ = refl
  assoc-ren-ren (T₁ ⇒ T₂) ρ₁ ρ₂ = cong₂ _⇒_ (assoc-ren-ren T₁ ρ₁ ρ₂) (assoc-ren-ren T₂ ρ₁ ρ₂)
  assoc-ren-ren (`∀α l , T) ρ₁ ρ₂ = cong (`∀α l ,_) (assoc-ren↑-ren↑ T ρ₁ ρ₂)
  assoc-ren-ren 𝟙 ρ₁ ρ₂ = refl

↑ρ-TwkT≡Twk-ρT : ∀ (T : Type Δ₁ l′) (ρ : TRen Δ₁ Δ₂) →
  Tren (Tliftᵣ ρ l) (Twk T) ≡ Twk (Tren ρ T) 
↑ρ-TwkT≡Twk-ρT {l = l} T ρ = 
  begin 
    Tren (Tliftᵣ ρ _) (Tren (Twkᵣ Tidᵣ) T)
  ≡⟨ assoc-ren-ren T (Twkᵣ Tidᵣ) (Tliftᵣ ρ _) ⟩
    Tren ((Twkᵣ Tidᵣ) ρρ→ρ Tliftᵣ ρ _) T
  ≡⟨ sym (assoc-ren-ren T ρ (Twkᵣ Tidᵣ)) ⟩
    Tren (Twkᵣ Tidᵣ) (Tren ρ T)
  ∎

ren↑-dist-σρ→σ : ∀ l (σ : TSub Δ₁ Δ₂) (ρ : TRen Δ₂ Δ₃) →
  Tliftₛ (σ σρ→σ ρ) l ≡ (Tliftₛ σ l σρ→σ Tliftᵣ ρ _)
ren↑-dist-σρ→σ l σ ρ = fun-ext₂ λ where 
   _ here → refl
   _ (there x) → sym (↑ρ-TwkT≡Twk-ρT (σ _ x) ρ)

mutual 
  assoc-ren↑-sub↑ : ∀ (T : Type (l ∷ Δ₁) l′) (σ : TSub Δ₁ Δ₂) (ρ : TRen Δ₂ Δ₃) →
    Tren (Tliftᵣ ρ _) (Tsub (Tliftₛ σ _) T) ≡ Tsub (Tliftₛ (σ σρ→σ ρ) _) T
  assoc-ren↑-sub↑ {l = l} T σ ρ = begin 
      Tren (Tliftᵣ ρ _) (Tsub (Tliftₛ σ _) T)
    ≡⟨ assoc-ren-sub T (Tliftₛ σ _) (Tliftᵣ ρ _) ⟩
      Tsub (Tliftₛ σ _ σρ→σ Tliftᵣ ρ _) T
    ≡⟨ cong (λ σ → Tsub σ T) (sym (ren↑-dist-σρ→σ l σ ρ)) ⟩
      Tsub (Tliftₛ (σ σρ→σ ρ) _) T
    ∎ 

  assoc-ren-sub : ∀ (T : Type Δ₁ l) (σ : TSub Δ₁ Δ₂) (ρ : TRen Δ₂ Δ₃) →
    Tren ρ (Tsub σ T) ≡ Tsub (σ σρ→σ ρ) T
  assoc-ren-sub (` x) ρ σ = refl
  assoc-ren-sub (T₁ ⇒ T₂) ρ σ = cong₂ _⇒_ (assoc-ren-sub T₁ ρ σ) (assoc-ren-sub T₂ ρ σ)
  assoc-ren-sub (`∀α l , T) ρ σ = cong (`∀α l ,_) (assoc-ren↑-sub↑ T ρ σ)
  assoc-ren-sub 𝟙 ρ σ = refl

σ↑-TwkT≡Twk-σT : ∀ {l} (σ : TSub Δ₁ Δ₂) (T : Type Δ₁ l′) →
  Tsub (Tliftₛ σ _) (Twk {l = l} T) ≡ Twk (Tsub σ T)
σ↑-TwkT≡Twk-σT σ T = 
  begin 
    Tsub (Tliftₛ σ _) (Twk T) 
  ≡⟨ assoc-sub-ren T (Twkᵣ Tidᵣ) (Tliftₛ σ _) ⟩
    Tsub (σ σρ→σ λ _ → there) T
  ≡⟨ sym (assoc-ren-sub T σ (Twkᵣ Tidᵣ)) ⟩
    Tren (Twkᵣ Tidᵣ) (Tsub σ T)
  ∎


sub↑-dist-σσ→σ : ∀ l (σ₁ : TSub Δ₁ Δ₂) (σ₂ : TSub Δ₂ Δ₃) →
  Tliftₛ (σ₁ σσ→σ σ₂) _  ≡ (Tliftₛ σ₁ l σσ→σ Tliftₛ σ₂ _)
sub↑-dist-σσ→σ l σ₁ σ₂ = fun-ext₂ λ where 
  _ here → refl
  l′ (there x) → begin 
        (Tliftₛ (σ₁ σσ→σ σ₂) l) l′ (there x) 
      ≡⟨ sym (σ↑-TwkT≡Twk-σT {l = l} σ₂ (σ₁ l′ x)) ⟩
        (Tliftₛ σ₁ _ σσ→σ Tliftₛ σ₂ _) l′ (there x)
      ∎

mutual 
  assoc-sub↑-sub↑ : ∀ (T : Type (l ∷ Δ₁) l′) (σ₁ : TSub Δ₁ Δ₂) (σ₂ : TSub Δ₂ Δ₃) →
    Tsub (Tliftₛ σ₂ _) (Tsub (Tliftₛ σ₁ _) T) ≡ Tsub (Tliftₛ (σ₁ σσ→σ σ₂) _) T
  assoc-sub↑-sub↑ {l = l} T σ₁ σ₂ = begin 
      Tsub (Tliftₛ σ₂ _) (Tsub (Tliftₛ σ₁ _) T)
    ≡⟨ assoc-sub-sub T (Tliftₛ σ₁ _) (Tliftₛ σ₂ _) ⟩
      Tsub (Tliftₛ σ₁ _ σσ→σ Tliftₛ σ₂ _) T
    ≡⟨ cong (λ σ → Tsub σ T) (sym (sub↑-dist-σσ→σ l σ₁ σ₂)) ⟩
      Tsub (Tliftₛ (σ₁ σσ→σ σ₂) _) T
    ∎ 

  assoc-sub-sub : ∀ (T : Type Δ₁ l) (σ₁ : TSub Δ₁ Δ₂) (σ₂ : TSub Δ₂ Δ₃) →
    Tsub σ₂ (Tsub σ₁ T) ≡ Tsub (σ₁ σσ→σ σ₂) T
  assoc-sub-sub (` x) σ₁ σ₂ = refl
  assoc-sub-sub (T₁ ⇒ T₂) σ₁ σ₂ = cong₂ _⇒_ (assoc-sub-sub T₁ σ₁ σ₂) (assoc-sub-sub T₂ σ₁ σ₂)
  assoc-sub-sub (`∀α l , T) σ₁ σ₂ = cong (`∀α l ,_) (assoc-sub↑-sub↑ T σ₁ σ₂)
  assoc-sub-sub 𝟙 σ₁ σ₂ = refl

-- type in expr renamings

TliftᵣTidᵣ≡Tidᵣ : ∀ Δ l →
  (Tliftᵣ {Δ₁ = Δ} Tidᵣ l) ≡ Tidᵣ
TliftᵣTidᵣ≡Tidᵣ _ _ = fun-ext₂ λ where
  _ here → refl
  _ (there x) → refl

TidᵣT≡T : ∀ (T : Type Δ l) → Tren Tidᵣ T ≡ T
TidᵣT≡T (` x) = refl
TidᵣT≡T (T₁ ⇒ T₂) = cong₂ _⇒_ (TidᵣT≡T T₁) (TidᵣT≡T T₂)
TidᵣT≡T {Δ = Δ} (`∀α l , T) rewrite TliftᵣTidᵣ≡Tidᵣ Δ l = cong (`∀α l ,_) (TidᵣT≡T T)
TidᵣT≡T 𝟙 = refl


ρ[T]≡[ρT]ρ↑ : ∀ (T : Type Δ₁ l) (ρ : TRen Δ₁ Δ₂) →
  Textₛ Tidₛ T σρ→σ ρ ≡ (Tliftᵣ ρ _) ρσ→σ Textₛ Tidₛ (Tren ρ T)
ρ[T]≡[ρT]ρ↑ T ρ = fun-ext₂ λ where 
  _ here → refl
  _ (there x) → refl

ρT[T′]≡ρT[ρ↑T′] : ∀ (ρ : TRen Δ₁ Δ₂) (T : Type (l ∷ Δ₁) l′) (T′ : Type Δ₁ l) →
  Tren ρ (T [ T′ ]T) ≡ Tren (Tliftᵣ ρ _) T [ Tren ρ T′ ]T 
ρT[T′]≡ρT[ρ↑T′] ρ T T′ = begin 
    Tren ρ (T [ T′ ]T)
  ≡⟨ assoc-ren-sub T (Textₛ Tidₛ T′) ρ ⟩
    Tsub (Textₛ Tidₛ T′ σρ→σ ρ) T
  ≡⟨ cong (λ σ → Tsub σ T) (ρ[T]≡[ρT]ρ↑ T′ ρ) ⟩
    Tsub ((Tliftᵣ ρ _) ρσ→σ (Textₛ Tidₛ (Tren ρ T′))) T
  ≡⟨ sym (assoc-sub-ren T (Tliftᵣ ρ _) (Textₛ Tidₛ (Tren ρ T′))) ⟩
    Tsub (Textₛ Tidₛ (Tren ρ T′)) (Tren (Tliftᵣ ρ _) T)
  ∎

data OPE : TRen Δ₁ Δ₂ → TEnv Δ₁ → TEnv Δ₂ → Set where
  ope-id : ∀ {Δ} {Γ : TEnv Δ} →
    OPE Tidᵣ Γ Γ
  ope-lift₁ : ∀ {l} {Δ₁} {Δ₂} {Γ₁ : TEnv Δ₁} {Γ₂ : TEnv Δ₂} {ρ : TRen Δ₁ Δ₂} →
    (ope : OPE ρ Γ₁ Γ₂) → OPE (Tliftᵣ ρ _) (l ◁* Γ₁) (l ◁* Γ₂)
  ope-wk : ∀ {l} {Δ₁} {Δ₂} {Γ₁ : TEnv Δ₁} {Γ₂ : TEnv Δ₂} {ρ : TRen Δ₁ Δ₂} →
    (ope : OPE ρ Γ₁ Γ₂) → OPE (Twkᵣ ρ) Γ₁ (l ◁* Γ₂)
  ope-lift₂ : ∀ {l} {Δ₁} {Δ₂} {Γ₁ : TEnv Δ₁} {Γ₂ : TEnv Δ₂} {T : Type Δ₁ l} {ρ : TRen Δ₁ Δ₂}
    (ope : OPE ρ Γ₁ Γ₂) → OPE ρ (T ◁ Γ₁) (Tren ρ T ◁ Γ₂) 
  
ETren-x : {ρ : TRen Δ₁ Δ₂} → (ope : OPE ρ Γ₁ Γ₂) → inn T Γ₁ → inn (Tren ρ T) Γ₂
ETren-x {T = T} {ρ = ρ} ope-id x rewrite TidᵣT≡T T = x
ETren-x {ρ = .(Tliftᵣ _ _)} (ope-lift₁ ope) (tskip x) = 
  subst (λ T → inn T _) (sym (↑ρ-TwkT≡Twk-ρT _ _)) (tskip (ETren-x ope x))
ETren-x {ρ = .(Twkᵣ _)} (ope-wk ope) x = subst (λ T → inn T _) (assoc-ren-ren _ _ (Twkᵣ Tidᵣ)) (tskip (ETren-x ope x))
ETren-x {ρ = ρ} (ope-lift₂ ope) here = here
ETren-x {ρ = ρ} (ope-lift₂ ope) (there x) = there (ETren-x ope x)

ETren : {ρ : TRen Δ₁ Δ₂} → (ope : OPE ρ Γ₁ Γ₂) → Expr Δ₁ Γ₁ T → Expr Δ₂ Γ₂ (Tren ρ T)
ETren ope (` x) = ` ETren-x ope x
ETren ope (ƛ e) = ƛ ETren (ope-lift₂ ope) e
ETren ope (e₁ · e₂) = ETren ope e₁ · ETren ope e₂
ETren {ρ = ρ} ope (Λ l ⇒ e) = Λ l ⇒ ETren (ope-lift₁ ope) e
ETren {Δ₂ = Δ₂} {Γ₁ = Γ₁} {Γ₂ = Γ₂} {ρ = ρ}  ope (_∙_ {T = T} e T′) = 
  subst (λ T → Expr Δ₂ Γ₂ T) (sym (ρT[T′]≡ρT[ρ↑T′] ρ T T′)) (ETren ope e ∙ Tren ρ T′) 

Ewk-l : Expr Δ Γ T → Expr (l ∷ Δ) (l ◁* Γ) (Twk T)  
Ewk-l {Δ = Δ} {Γ = Γ} {T = T} {l = l} e = ETren (ope-wk ope-id) e

-- type in expr substituions

data SUB : TSub Δ₁ Δ₂ → TEnv Δ₁ → TEnv Δ₂ → Set where
  sub-id : ∀ {Δ} {Γ : TEnv Δ} →
    SUB Tidₛ Γ Γ
  sub-lift₁ : ∀ {l} {Δ₁} {Δ₂} {Γ₁ : TEnv Δ₁} {Γ₂ : TEnv Δ₂} {σ : TSub Δ₁ Δ₂} →
    (sub : SUB σ Γ₁ Γ₂) → SUB (Tliftₛ σ _) (l ◁* Γ₁) (l ◁* Γ₂)
  sub-ext : ∀ {l} {Δ₁} {Δ₂} {Γ₁ : TEnv Δ₁} {Γ₂ : TEnv Δ₂} {σ : TSub Δ₁ Δ₂} {T : Type Δ₂ l} →
    (sub : SUB σ Γ₁ Γ₂) → SUB (Textₛ σ T) (l ◁* Γ₁) Γ₂
  sub-lift₂ : ∀ {l} {Δ₁} {Δ₂} {Γ₁ : TEnv Δ₁} {Γ₂ : TEnv Δ₂} {σ : TSub Δ₁ Δ₂} {T : Type Δ₁ l} →
    (sub : SUB σ Γ₁ Γ₂) → SUB σ (T ◁ Γ₁) (Tsub σ T ◁ Γ₂)

TliftₛTidₛ≡Tidₛ : ∀ Δ l →                         
  (Tliftₛ {Δ₁ = Δ} Tidₛ l) ≡ Tidₛ
TliftₛTidₛ≡Tidₛ _ _ = fun-ext₂ λ where
  _ here → refl
  _ (there x) → refl             

TidₛT≡T : ∀ (T : Type Δ l) → Tsub Tidₛ T ≡ T       
TidₛT≡T (` x) = refl
TidₛT≡T (T₁ ⇒ T₂) = cong₂ _⇒_ (TidₛT≡T T₁) (TidₛT≡T T₂)
TidₛT≡T {Δ = Δ} (`∀α l , T) rewrite TliftₛTidₛ≡Tidₛ Δ l = cong (`∀α l ,_) (TidₛT≡T T)
TidₛT≡T 𝟙 = refl

σ[T]≡[σT]σ↑ : ∀ (T : Type Δ₁ l) (σ : TSub Δ₁ Δ₂) →
  (Textₛ Tidₛ T σσ→σ σ) ≡ ((Tliftₛ σ _) σσ→σ (Textₛ Tidₛ (Tsub σ T)))
σ[T]≡[σT]σ↑ T σ = fun-ext₂ λ where
  _ here → refl
  _ (there x) → begin 
        σ _ x
      ≡⟨ sym (TidₛT≡T (σ _ x)) ⟩
        Tsub Tidₛ (σ _ x)
      ≡⟨ sym (assoc-sub-ren (σ _ x) (Twkᵣ Tidᵣ) (Textₛ Tidₛ (Tsub σ T))) ⟩
        Tsub (Textₛ Tidₛ (Tsub σ T)) (Twk (σ _ x))
      ∎

σT[T′]≡σ↑T[σT'] : ∀ (σ : TSub Δ₁ Δ₂) (T : Type (l ∷ Δ₁) l′) (T′ : Type Δ₁ l) →
  Tsub σ (T [ T′ ]T) ≡ (Tsub (Tliftₛ σ _) T) [ Tsub σ T′ ]T  
σT[T′]≡σ↑T[σT'] σ T T′ = 
  begin 
    Tsub σ (T [ T′ ]T) 
  ≡⟨ assoc-sub-sub T (Textₛ Tidₛ T′) σ ⟩
    Tsub (Textₛ Tidₛ T′ σσ→σ σ) T
  ≡⟨ cong (λ σ → Tsub σ T) (σ[T]≡[σT]σ↑ T′ σ) ⟩
    Tsub (Tliftₛ σ _ σσ→σ Textₛ Tidₛ (Tsub σ T′)) T
  ≡⟨ sym (assoc-sub-sub T (Tliftₛ σ _) (Textₛ Tidₛ (Tsub σ T′))) ⟩
    (Tsub (Tliftₛ σ _) T) [ Tsub σ T′ ]T
  ∎

σT≡TextₛσTwkT : {T′ : Type Δ₂ l′} (σ : TSub Δ₁ Δ₂) (T : Type Δ₁ l) → Tsub (Textₛ σ T′) (Twk T) ≡ Tsub σ T
σT≡TextₛσTwkT {T′ = T′} σ T = begin 
    Tsub (Textₛ σ _) (Twk T)
  ≡⟨ assoc-sub-ren T (Twkᵣ Tidᵣ) (Textₛ σ _) ⟩
    Tsub (Twkᵣ Tidᵣ ρσ→σ Textₛ σ T′) T
  ≡⟨ sym (assoc-sub-sub T _ σ) ⟩
    Tsub σ (Tsub Tidₛ T)
  ≡⟨ cong (λ T → Tsub σ T) (TidₛT≡T T) ⟩
    Tsub σ T
  ∎

ETsub-x : {σ : TSub Δ₁ Δ₂} → SUB σ Γ₁ Γ₂ → inn T Γ₁ → inn (Tsub σ T) Γ₂
ETsub-x {T = T} sub-id x rewrite TidₛT≡T T = x
ETsub-x {T = .(Twk T)} {σ = .(Tliftₛ _ _)} (sub-lift₁ sub) (tskip {T = T} x) = 
  subst (λ T → inn T _) (sym (σ↑-TwkT≡Twk-σT _ T)) (tskip (ETsub-x sub x))
ETsub-x {T = .(Twk T)} (sub-ext sub) (tskip {T = T} x) = 
  subst (λ T → inn T _) (sym (σT≡TextₛσTwkT _ T)) (ETsub-x sub x)
ETsub-x (sub-lift₂ sub) here = here
ETsub-x (sub-lift₂ sub) (there x) = there (ETsub-x sub x)

ETsub : {σ : TSub Δ₁ Δ₂} → SUB σ Γ₁ Γ₂ → Expr Δ₁ Γ₁ T → Expr Δ₂ Γ₂ (Tsub σ T)
ETsub sub (` x) = ` ETsub-x sub x
ETsub sub (ƛ e) = ƛ ETsub (sub-lift₂ sub) e
ETsub sub (e₁ · e₂) = ETsub sub e₁ · ETsub sub e₂
ETsub sub (Λ l ⇒ e) = Λ l ⇒ ETsub (sub-lift₁ sub) e
ETsub {Δ₂ = Δ₂} {Γ₂ = Γ₂} {σ = σ} sub (_∙_ {T = T} e T′) = 
  subst (λ T → Expr Δ₂ Γ₂ T) (sym (σT[T′]≡σ↑T[σT'] σ T T′)) (ETsub sub e ∙ Tsub σ T′)

_[_]ET : Expr (l ∷ Δ) (l ◁* Γ) T → (T′ : Type Δ l) → Expr Δ Γ (T [ T′ ]T)
e [ T ]ET = ETsub (sub-ext sub-id) e 

-- expr in expr substitution

ERen : TEnv Δ → TEnv Δ → Set
ERen {Δ} Γ₁ Γ₂ = ∀ {l} {T : Type Δ l} → inn T Γ₁ → inn T Γ₂

Ewkᵣ : ERen Γ (T ◁ Γ) 
Ewkᵣ = there

Eliftᵣ : ERen Γ₁ Γ₂ → ERen (T ◁ Γ₁) (T ◁ Γ₂)
Eliftᵣ ρ here = here
Eliftᵣ ρ (there x) = there (ρ x)

Eliftᵣ-l : ERen Γ₁ Γ₂ → ERen (l ◁* Γ₁) (l ◁* Γ₂)
Eliftᵣ-l ρ (tskip x) = tskip (ρ x) 

Eren : ERen Γ₁ Γ₂ → (Expr Δ Γ₁ T → Expr Δ Γ₂ T)
Eren ρ (` x) = ` ρ x
Eren ρ (ƛ e) = ƛ Eren (Eliftᵣ ρ) e
Eren ρ (e₁ · e₂) = Eren ρ e₁ · Eren ρ e₂
Eren ρ (Λ l ⇒ e) = Λ l ⇒ Eren (Eliftᵣ-l ρ) e
Eren ρ (e ∙ T′) = Eren ρ e ∙ T′

Ewk : Expr Δ Γ T → Expr Δ (T₁ ◁ Γ) T 
Ewk = Eren Ewkᵣ

ESub : TEnv Δ → TEnv Δ → Set
ESub {Δ} Γ₁ Γ₂ = ∀ {l} {T : Type Δ l} → inn T Γ₁ → Expr Δ Γ₂ T

Eidₛ : ESub Γ Γ
Eidₛ = `_

Ewkₛ : ESub Γ₁ Γ₂ → ESub Γ₁ (T ◁ Γ₂)
Ewkₛ σ x = Ewk (σ x)

Eliftₛ : ESub Γ₁ Γ₂ → ESub (T ◁ Γ₁) (T ◁ Γ₂)
Eliftₛ σ here = ` here
Eliftₛ σ (there x) = Ewk (σ x)

Eliftₛ-l : ESub Γ₁ Γ₂ → ESub (l ◁* Γ₁) (l ◁* Γ₂)
Eliftₛ-l σ (tskip x) = Ewk-l (σ x)

Esub : ESub Γ₁ Γ₂ → Expr Δ Γ₁ T → Expr Δ Γ₂ T
Esub σ (` x) = σ x
Esub σ (ƛ e) = ƛ Esub (Eliftₛ σ) e
Esub σ (e₁ · e₂) = Esub σ e₁ · Esub σ e₂
Esub σ (Λ l ⇒ e) = Λ l ⇒ Esub (Eliftₛ-l σ) e
Esub σ (e ∙ T) = Esub σ e ∙ T

Eextₛ : ESub Γ₁ Γ₂ → Expr Δ Γ₂ T → ESub (T ◁ Γ₁) Γ₂
Eextₛ σ e' here = e'
Eextₛ σ e' (there x) = σ x

_[_]E : Expr Δ (T₁ ◁ Γ) T₂ → Expr Δ Γ T₁ → Expr Δ Γ T₂
_[_]E e e' = Esub (Eextₛ Eidₛ e') e

-- small step call by value semantics

data Val : Expr Δ Γ T → Set where
  v-ƛ : Val (ƛ e)
  v-Λ : Val (Λ l ⇒ e)

data _↪_ : Expr Δ Γ T → Expr Δ Γ T → Set where
  β-ƛ : 
     Val e₂ →
     ((ƛ e₁) · e₂) ↪ (e₁ [ e₂ ]E)
  β-Λ :
     ((Λ l ⇒ e) ∙ T) ↪ (e [ T ]ET)
  ξ-·₁ :
    e₁ ↪ e →
    (e₁ · e₂) ↪ (e · e₂)
  ξ-·₂ : 
    e₂ ↪ e → 
    Val e₁ →
    (e₁ · e₂) ↪ (e₁ · e)
  ξ-∙ :
    e₁ ↪ e₂ →
    (e₁ ∙ T′) ↪ (e₂ ∙ T′)

{- data _↪*_ : Expr Δ Γ T → Expr Δ Γ T → Set where
  refl :
    e ↪* e
  step :
    e₁ ↪* e₂ →
    e₂ ↪ e₃ →
    e₁ ↪* e₃ -}

subst-to-env : ∀ {η : Env* Δ} → (σ : ESub Γ₁ Γ₂) → (γ : Env Δ Γ₂ η) → Env Δ Γ₁ η
subst-to-env = {!   !}

Esubst-preserves : ∀ {η : Env* Δ} {γ : Env Δ Γ₂ η} → (σ : ESub Γ₁ Γ₂) (e : Expr Δ Γ₁ T)
  → E⟦ Esub σ e ⟧ η γ ≡ E⟦ e ⟧ η (subst-to-env σ γ)
Esubst-preserves = {!   !}

Esingle-subst-preserves : ∀ {η : Env* Δ} (γ : Env Δ Γ η) (e₁ : Expr Δ (T′ ◁ Γ) T) (e₂ : Expr Δ Γ T′) →
  E⟦ e₁ [ e₂ ]E ⟧ η γ ≡ E⟦ e₁ ⟧ η (extend γ (E⟦ e₂ ⟧ η γ))  
Esingle-subst-preserves γ e₁ e₂ = {!   !}

adequacy : ∀ {e₁ e₂ : Expr Δ Γ T}{η : Env* Δ}{γ : Env Δ Γ η} → e₁ ↪ e₂ → E⟦ e₁ ⟧ η γ ≡ E⟦ e₂ ⟧ η γ
adequacy (β-ƛ v₂) = {!   !}
adequacy (β-Λ) = {!   !}
adequacy {η = η} {γ = γ} (ξ-·₁ {e₂ = e₂} e₁↪e) = cong-app (adequacy e₁↪e) (E⟦ e₂ ⟧ η γ)
adequacy {η = η} {γ = γ} (ξ-·₂ {e₁ = e₁} e₂↪e v₁) = cong (E⟦ e₁ ⟧ η γ) (adequacy e₂↪e)
adequacy {η = η} {γ = γ} (ξ-∙ {e₁ = e₁} {e₂ = e₂} {T′ = T′} e₁↪e₂) 
  with cong-app (adequacy {η = η} {γ = γ} e₁↪e₂) (⟦ T′ ⟧ η)
... | b = {!   !}  