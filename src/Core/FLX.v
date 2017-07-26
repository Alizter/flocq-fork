(**
This file is part of the Flocq formalization of floating-point
arithmetic in Coq: http://flocq.gforge.inria.fr/

Copyright (C) 2010-2013 Sylvie Boldo
#<br />#
Copyright (C) 2010-2013 Guillaume Melquiond

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
COPYING file for more details.
*)

(** * Floating-point format without underflow *)
Require Import Raux Definitions Round_pred Generic_fmt Float_prop.
Require Import FIX Ulp Round_NE.

Record Prec_gt_0 := {
  prec :> Z ;
  prec_gt_0 : (0 < prec)%Z
}.

Section RND_FLX.

Variable beta : radix.

Notation bpow e := (bpow beta e).

Section prec.

Variable prec : Z.

Inductive FLX_format (x : R) : Prop :=
  FLX_spec (f : float beta) :
    x = F2R f -> (Zabs (Fnum f) < Zpower beta prec)%Z -> FLX_format x.

(** unbounded floating-point format with normal mantissas *)
Inductive FLXN_format (x : R) : Prop :=
  FLXN_spec (f : float beta) :
    x = F2R f ->
    (x <> 0%R -> Zpower beta (prec - 1) <= Zabs (Fnum f) < Zpower beta prec)%Z ->
    FLXN_format x.

Definition FLX_exp (e : Z) := (e - prec)%Z.

(** Properties of the FLX format *)

Lemma FLX_exp_valid1 :
  forall k : Z, (FLX_exp k < k)%Z ->
  (FLX_exp (k + 1) <= k)%Z.
Proof.
intros k.
unfold FLX_exp.
omega.
Qed.

End prec.

Section Prec_gt_0.

Variable prec : Prec_gt_0.

Local Notation FLX_exp' := FLX_exp (only parsing).
Local Notation FLX_format' := FLX_format (only parsing).
Notation FLX_exp := (FLX_exp prec).
Notation FLX_format := (FLX_format prec).

Lemma FLX_exp_valid2 :
  forall k : Z, (k <= FLX_exp k)%Z ->
  (FLX_exp (FLX_exp k + 1) <= FLX_exp k)%Z.
Proof.
intros k.
unfold FLX_exp.
generalize (prec_gt_0 prec).
omega.
Qed.

Lemma FLX_exp_valid3 :
  forall k l : Z,
  (k <= FLX_exp k)%Z -> (l <= FLX_exp k)%Z ->
  FLX_exp l = FLX_exp k.
Proof.
intros k l.
unfold FLX_exp.
generalize (prec_gt_0 prec).
omega.
Qed.

Canonical Structure FLX_exp_valid :=
  Build_Valid_exp FLX_exp (FLX_exp_valid1 prec) FLX_exp_valid2 FLX_exp_valid3.

Theorem FIX_format_FLX :
  forall (prec : Z) x e,
  (bpow (e - 1) <= Rabs x <= bpow e)%R ->
  FLX_format' prec x ->
  FIX_format beta (e - prec) x.
Proof.
clear prec.
intros prec x e Hx [[xm xe] H1 H2].
rewrite H1, (F2R_prec_normalize beta xm xe e prec).
now eexists.
exact H2.
now rewrite <- H1.
Qed.

Theorem FLX_format_generic :
  forall x, generic_format beta FLX_exp x -> FLX_format x.
Proof.
intros x H.
rewrite H.
eexists ; repeat split.
simpl.
apply lt_Z2R.
rewrite Z2R_abs.
rewrite <- scaled_mantissa_generic with (1 := H).
rewrite <- scaled_mantissa_abs.
apply Rmult_lt_reg_r with (bpow (cexp beta FLX_exp (Rabs x))).
apply bpow_gt_0.
rewrite scaled_mantissa_mult_bpow.
rewrite Z2R_Zpower, <- bpow_plus.
2: apply Zlt_le_weak, prec_gt_0.
unfold cexp, FLX_exp.
ring_simplify (prec + (mag beta (Rabs x) - prec))%Z.
rewrite mag_abs.
destruct (Req_dec x 0) as [Hx|Hx].
rewrite Hx, Rabs_R0.
apply bpow_gt_0.
destruct (mag beta x) as (ex, Ex).
now apply Ex.
Qed.

Theorem generic_format_FLX :
  forall prec x, FLX_format' prec x -> generic_format beta (FLX_exp' prec) x.
Proof.
clear prec.
intros prec x [[mx ex] H1 H2].
simpl in H2.
rewrite H1.
apply generic_format_F2R.
intros Zmx.
unfold cexp, FLX_exp.
rewrite mag_F2R with (1 := Zmx).
apply Zplus_le_reg_r with (prec - ex)%Z.
ring_simplify.
now apply mag_le_Zpower.
Qed.

Theorem FLX_format_satisfies_any :
  satisfies_any FLX_format.
Proof.
eapply satisfies_any_eq.
intros x.
split.
apply FLX_format_generic.
apply generic_format_FLX.
apply generic_format_satisfies_any.
Qed.

Theorem FLX_format_FIX :
  forall x e,
  (bpow (e - 1) <= Rabs x <= bpow e)%R ->
  FIX_format beta (e - prec) x ->
  FLX_format x.
Proof.
intros x e Hx Fx.
apply FLX_format_generic.
apply generic_format_FIX in Fx.
revert Fx.
apply generic_inclusion with (2 := Hx).
apply Zle_refl.
Qed.

Theorem generic_format_FLXN :
  forall prec x, FLXN_format prec x -> generic_format beta (FLX_exp' prec) x.
Proof.
clear prec.
intros prec x [[xm ex] H1 H2].
destruct (Req_dec x 0) as [Zx|Zx].
rewrite Zx.
apply generic_format_0.
specialize (H2 Zx).
apply generic_format_FLX.
rewrite H1.
eexists ; repeat split.
apply H2.
Qed.

Theorem FLXN_format_generic :
  forall x, generic_format beta FLX_exp x -> FLXN_format prec x.
Proof.
intros x Hx.
rewrite Hx.
simpl.
eexists. easy.
rewrite <- Hx.
intros Zx.
simpl.
split.
(* *)
apply le_Z2R.
rewrite Z2R_Zpower.
2: apply Zlt_0_le_0_pred, prec_gt_0.
rewrite Z2R_abs, <- scaled_mantissa_generic with (1 := Hx).
apply Rmult_le_reg_r with (bpow (cexp beta FLX_exp x)).
apply bpow_gt_0.
rewrite <- bpow_plus.
rewrite <- scaled_mantissa_abs.
rewrite <- cexp_abs.
rewrite scaled_mantissa_mult_bpow.
unfold cexp, FLX_exp.
rewrite mag_abs.
ring_simplify (prec - 1 + (mag beta x - prec))%Z.
destruct (mag beta x) as (ex,Ex).
now apply Ex.
(* *)
apply lt_Z2R.
rewrite Z2R_Zpower.
2: apply Zlt_le_weak, prec_gt_0.
rewrite Z2R_abs, <- scaled_mantissa_generic with (1 := Hx).
apply Rmult_lt_reg_r with (bpow (cexp beta FLX_exp x)).
apply bpow_gt_0.
rewrite <- bpow_plus.
rewrite <- scaled_mantissa_abs.
rewrite <- cexp_abs.
rewrite scaled_mantissa_mult_bpow.
unfold cexp, FLX_exp.
rewrite mag_abs.
ring_simplify (prec + (mag beta x - prec))%Z.
destruct (mag beta x) as (ex,Ex).
now apply Ex.
Qed.

Theorem FLXN_format_satisfies_any :
  satisfies_any (FLXN_format prec).
Proof.
eapply satisfies_any_eq.
split.
apply FLXN_format_generic.
apply generic_format_FLXN.
apply generic_format_satisfies_any.
Qed.

Theorem ulp_FLX_0: ulp beta FLX_exp 0 = 0%R.
Proof.
unfold ulp; rewrite Req_bool_true; trivial.
case (negligible_exp_spec FLX_exp).
intros _; reflexivity.
intros n H2; contradict H2.
unfold FLX_exp.
generalize (prec_gt_0 prec); omega.
Qed.

Theorem ulp_FLX_le :
  forall x, (ulp beta FLX_exp x <= Rabs x * bpow (1-prec))%R.
Proof.
intros x; case (Req_dec x 0); intros Hx.
rewrite Hx, ulp_FLX_0, Rabs_R0.
right; ring.
rewrite ulp_neq_0; try exact Hx.
unfold cexp, FLX_exp.
replace (mag beta x - prec)%Z with ((mag beta x - 1) + (1-prec))%Z by ring.
rewrite bpow_plus.
apply Rmult_le_compat_r.
apply bpow_ge_0.
now apply bpow_mag_le.
Qed.

Theorem ulp_FLX_ge :
  forall x, (Rabs x * bpow (-prec) <= ulp beta FLX_exp x)%R.
Proof.
intros x; case (Req_dec x 0); intros Hx.
rewrite Hx, ulp_FLX_0, Rabs_R0.
right; ring.
rewrite ulp_neq_0; try exact Hx.
unfold cexp, FLX_exp.
unfold Zminus; rewrite bpow_plus.
apply Rmult_le_compat_r.
apply bpow_ge_0.
left; now apply bpow_mag_gt.
Qed.

(** FLX is a nice format: it has a monotone exponent... *)
Global Instance FLX_exp_monotone : Monotone_exp FLX_exp_valid.
Proof.
intros ex ey Hxy.
now apply Zplus_le_compat_r.
Qed.

(** and it allows a rounding to nearest, ties to even. *)
Hypothesis NE_prop : Zeven beta = false \/ (1 < prec)%Z.

Global Instance exists_NE_FLX : Exists_NE beta FLX_exp_valid.
Proof.
destruct NE_prop as [H|H].
now left.
right.
simpl.
unfold FLX_exp.
split ; omega.
Qed.

End Prec_gt_0.

End RND_FLX.
