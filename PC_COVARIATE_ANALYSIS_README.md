# PC Covariate Analysis - Implementation Guide

## Overview

PCA/LSIタブに新しい「PC Covariate Analysis」タブを追加しました。このタブでは、各主成分(PC)がどの共変量（細胞サブタイプ、性差、バッチ、年齢など）によってどの程度説明されるかを定量化・可視化できます。

## 実装したファイル

### 1. `pc_covariate_analysis.R`
解析用の主要関数を含むRスクリプト：

#### 主要関数：

- **`analyze_pc_covariates()`**: 主解析関数
  - 各PCに対して線形モデル（固定効果のみ）と混合効果モデル（オプション）をフィット
  - 各共変量の回帰係数、p値、partial R²を計算
  - 結果を3つのデータフレームで返す：
    - `per_pc_stats`: PC×共変量の統計サマリー
    - `model_details`: 詳細なモデル結果
    - `plot_data`: 可視化用データ

- **`plot_pc_vs_covariate()`**: 個別PCプロット関数
  - 指定したPC×共変量の散布図/箱ひげ図を生成
  - カテゴリ変数：箱ひげ図 + ジッタープロット
  - 連続変数：散布図 + 線形回帰線

- **`plot_partial_r2_heatmap()`**: Partial R²ヒートマップ
  - PC×共変量のpartial R²値をヒートマップで表示
  - どのPCがどの共変量で強く説明されるかが一目瞭然

- **`plot_pvalue_heatmap()`**: P値ヒートマップ
  - PC×共変量のp値（-log10変換）をヒートマップで表示
  - 統計的有意性を可視化

### 2. `ui.R`の変更
- PCAタブ内に「PC Covariate Analysis」タブを追加（1818-1917行目）
- UIコンポーネント：
  - Reduction選択（RNA.pca, ATAC.lsiなど）
  - 解析するPC数の指定（5-50）
  - 共変量選択（最大4つ）
  - ランダム効果選択（オプション）
  - 結果表示用のタブパネル：
    - Summary Statistics: 統計サマリーテーブル
    - Partial R² Heatmap: Partial R²ヒートマップ
    - P-value Heatmap: P値ヒートマップ
    - Individual PC Plots: 個別PC×共変量プロット

### 3. `server.R`の変更
- PC Covariate Analysis用のロジックを追加（9838-10172行目）
- 主要機能：
  - 共変量選択肢の自動更新（metadata列を取得）
  - Reduction選択肢の自動更新（利用可能なPCA/LSIを取得）
  - 解析実行ボタンのイベントハンドラ
  - 結果の可視化（テーブル、ヒートマップ、個別プロット）
  - ダウンロードハンドラ（CSV、PDF、ZIP）

## 使用方法

### 1. 基本的な使い方

1. **データのアップロードとPCA実行**
   - まず、「DATA INPUT」タブでデータをアップロード
   - 「PCA/LSI」タブの「PCA run」でPCAを実行

2. **PC Covariate Analysis タブに移動**
   - 「PCA/LSI」タブ内の「PC Covariate Analysis」タブをクリック

3. **パラメータの設定**
   - **Select reduction**: 使用するreductionを選択（例：RNA.pca）
   - **Number of PCs to analyze**: 解析するPC数を指定（デフォルト：5、最大20）
   - **Covariate 1-4**: 解析したい共変量を最大4つ選択
     - 例：subtype, sex, batch, ageなど
     - 不要な場合は"None"を選択（Resetボタンで全選択をクリア可能）
   - **Random effect 1-2 (optional)**: ランダム効果を最大2つ指定可能（例：sample, batch）
     - **重要**: scRNA-seqでは必ずsample/donorをRandom effect 1に指定（細胞の非独立性を調整）

4. **解析の実行**
   - 「Run Analysis」ボタンをクリック
   - 処理には数分かかる場合があります（データサイズ、PC数、共変量数による）

5. **結果の確認**
   - **Summary Statistics**: 各PC×共変量の統計サマリーを表示
     - Coefficients, p-values, partial R²など
   - **Partial R² Heatmap**: どのPCがどの共変量で強く説明されるか
   - **P-value Heatmap**: 統計的有意性の確認
   - **Individual PC Plots**: 個別のPC×共変量の関係をプロット

6. **結果のダウンロード**
   - 各タブにダウンロードボタンがあります
   - 「Download Results (ZIP)」で全結果を一括ダウンロード可能

### 2. 結果の解釈

#### Partial R²
- 各PC分散のうち、特定の共変量で説明される割合
- 0-1の範囲（0%から100%）
- 高い値 = そのPCはその共変量と強く関連

**重要な統計的注意点：**
- **交互作用を含むモデルの場合**：主効果のPartial R²には、その因子が関与する**すべての交互作用も含まれる**
  - 例：`sex`のPartial R² = `sex`主効果 + `sex:cell.ident`交互作用の総合寄与
  - これは「その因子の総合的な寄与」を示すため、解釈としては合理的
  - ただし「主効果のみの寄与」ではないことに注意

#### P値

**2種類のp値があります：**

1. **`fixed_pval_[共変量]`**: 個別係数のp値
   - 連続変数：その変数の傾きが0でないかを検定（これでOK）
   - **カテゴリカル変数：1つの水準（例：batchB）のp値のみ**
   - ⚠️ カテゴリカル変数では「因子全体の有意性」ではない

2. **`fixed_global_pval_[共変量]`**: 因子全体のp値（推奨）
   - F検定（線形モデル）またはLRT（混合モデル）から計算
   - カテゴリカル変数・連続変数の両方で「因子全体が有意か？」を正しく評価
   - **ヒートマップとプロットではこちらを使用**

**推奨：**
- カテゴリカル変数（batch, cell_type, sex等）：必ず`fixed_global_pval`を使用
- 連続変数（age等）：`fixed_pval`と`fixed_global_pval`は同じ

#### 固定効果 vs 混合効果モデル
- **固定効果モデル**: 全細胞を独立として扱う
- **混合効果モデル**: ドナーなどのグルーピング構造を考慮
  - Marginal R²: 固定効果のみで説明される分散
  - Conditional R²: 固定効果+ランダム効果で説明される分散

### 3. 典型的な使用例

#### 例1: バッチ効果の確認
```
Covariates: batch, orig.ident
目的: どのPCがバッチで説明されるか確認
→ Partial R²が高いPC = バッチ効果が強い
→ そのPCをクラスタリングから除外するか検討
```

#### 例2: 生物学的要因の探索
```
Covariates: cell_type, disease_status, age, sex
目的: どのPCが生物学的に意味のある変動を捉えているか
→ 高いpartial R²を持つPC = その要因で細胞が分離している
→ 重要なPCとして保持
```

#### 例3: ドナー効果の評価
```
Covariates: cell_type, treatment
Random effect: donor_id
目的: ドナー間の変動を考慮した解析
→ Marginal R²: cell_typeとtreatmentの純粋な効果
→ Conditional R² - Marginal R²: ドナー間変動
```

#### 例4: サブタイプ依存の性差解析（scRNA-seq）

**前提：**
- `sample`: マウス個体/ドナーID（同一sample由来の細胞は非独立）
- `sex`: 生物学的要因（オス/メス）
- `cell.ident`: 細胞サブタイプ/クラスタ（arterial, venous, capillaryなど）

**ステップ1: サブタイプ効果のみ**
```
Covariates: Covariate 1 = cell.ident
Random effect 1: sample
目的: PC1/PC2などがサブタイプで説明される軸かを確認
→ Partial R²が高い = サブタイプ主導のPC
```

**ステップ2: 主効果モデル（平均的な性差）**
```
Covariates: Covariate 1 = sex, Covariate 2 = cell.ident
Random effect 1: sample
Interaction: チェックなし
目的: サブタイプを調整した平均的な性差を評価
→ sexのpartial R²が有意 = どのサブタイプでも同方向の性差
→ Model Comparisonタブのf_test_pvalue（線形）またはlrt_pvalue（混合）で判定
```

**ステップ3: 交互作用モデル（サブタイプ依存の性差）**
```
Covariates: Covariate 1 = sex, Covariate 2 = cell.ident
Random effect 1: sample
Interaction: チェックあり（sex × cell.ident）
目的: サブタイプごとに性差の向きや大きさが異なるかを検定
→ Model Comparisonタブで「sex:cell.ident」のlrt_pvalue < 0.05 = サブタイプ依存の性差あり
→ 例：arterialでは♀>♂、venousでは♂>♀といった反転パターン
```

**統計的解釈の注意点：**
- **Random effect必須**: sample指定なし（単純なlm）では細胞の非独立性を無視し、p値が過度に有意になる
- **交互作用の判定**: Model Comparisonタブのlrt_pvalue（混合モデル）またはf_test_pvalue（線形モデル）で統計的有意性を確認
- **Marginal R² vs Conditional R²**: Marginal = 固定効果のみ、Conditional = 固定効果+ランダム効果
- **結論の書き方**: 「交互作用が有意（p < 0.05）なため、性差はサブタイプ依存的であり、特定のサブタイプでは性差の向きが逆転する」

## ダウンロードされるファイル（ZIP）

ZIPファイルには以下が含まれます：

1. **statistics_table.csv**: 統計サマリーテーブル
2. **plot_data.csv**: プロット用データ
3. **partial_r2_heatmap.pdf**: Partial R²ヒートマップ
4. **pvalue_heatmap.pdf**: P値ヒートマップ
5. **plots_[covariate].pdf**: 各共変量についての個別PCプロット（最大12 PC）
6. **README.txt**: 解析パラメータと結果ファイルの説明

## 必要なRパッケージ

以下のパッケージが必要です（通常、SCALAでインストール済み）：

```r
library(Seurat)
library(dplyr)
library(tidyr)
library(lme4)       # 混合効果モデル
library(lmerTest)   # 混合効果モデルのp値
library(MuMIn)      # R²計算
library(ggplot2)
library(broom)
```

インストールされていない場合：
```r
install.packages(c("lme4", "lmerTest", "MuMIn"))
```

## トラブルシューティング

### エラー: "Reduction not found"
- PCAをまだ実行していない可能性があります
- 「PCA run」タブでPCAを実行してください

### エラー: "Covariates not found in metadata"
- 選択した共変量名がmetadataに存在しない
- `seurat_object@meta.data`の列名を確認してください

### 警告: "Mixed model did not converge"
- 混合効果モデルが収束しなかった
- ランダム効果の構造が複雑すぎる可能性
- 固定効果モデルの結果のみを使用してください

### 解析が遅い
- PC数を減らす（20→10など）
- 共変量数を減らす
- ランダム効果を使わない

## 技術的な詳細

### モデル式

#### 固定効果モデル
```
PC_k ~ covariate1 + covariate2 + covariate3 + ...
```

#### 混合効果モデル
```
PC_k ~ covariate1 + covariate2 + ... + (1 | random_effect)
```

### Partial R²の計算方法
```
Partial R² = R²(full model) - R²(model without covariate)
```
各共変量を除いたモデルとフルモデルのR²の差を計算

### カテゴリ変数の扱い
- 自動的にfactorに変換
- baselineレベル（参照レベル）は最初のレベル
- 係数はbaselineとの比較を表す

## 参考文献・関連情報

このツールは以下の論文・手法に基づいています：

1. **Mixed effects models**: Bates et al. (2015) "Fitting Linear Mixed-Effects Models Using lme4"
2. **PCA quality control**: Hicks et al. (2018) "Missing data and technical variability in single-cell RNA-sequencing experiments"
3. **Batch effect assessment**: Tung et al. (2017) "Batch effects and the effective design of single-cell gene expression studies"

## 更新履歴

- **2025-10-29 (v2)**: 統計的妥当性の向上
  - **Global p-valueの追加**: カテゴリカル変数に対して因子全体のp値を計算・表示
    - `fixed_global_pval_[共変量]`: F検定から計算
    - `mixed_global_pval_[共変量]`: LRT（尤度比検定）から計算
  - **可視化の改善**:
    - カテゴリカル変数：Global p + Partial R²のみ表示
    - 連続変数：β + p + Partial R²を表示
  - **ヒートマップ**: Global p-valueを使用（統計的に正確）
  - **ドキュメント強化**: Partial R²の交互作用に関する注意点を明記
  - Resetボタン追加、Random effect 2個対応、Covariate 1×2交互作用のみ

- **2025-10-29 (v1)**: 初版リリース
  - PC共変量解析機能の実装
  - UI/サーバーロジックの統合
  - ヒートマップ可視化機能
  - ZIPダウンロード機能

## サポート

問題が発生した場合は、以下の情報を含めてご連絡ください：

1. エラーメッセージの全文
2. 使用したパラメータ（PC数、共変量名など）
3. データの基本情報（細胞数、metadata列名など）
4. Rのバージョンとパッケージのバージョン

---

**作成日**: 2025-10-29
**対象アプリケーション**: SCALA (Single-Cell Analysis Platform)
**実装者**: Claude Code
