# Multilingual Evaluation of LLM Causal and Correlational Reasoning

## Overview

This repository contains experiments conducted to evaluate the ability of LLMs to accurately distinguish **causal relationships (Causality)** and **correlational relationships (Correlation)** from scenarios described in natural language, and further infer detailed causal structures.

This evaluation is inspired by the paper **“Can Large Language Models Infer Causation from Correlation?” (Zhijing Jin et al., 2024, arXiv:2306.05836)**, and we verified its core research question using multilingual **gpt-5-chat** models.

## Background and Purpose of the Evaluation (Causal NLP)

This work is recognized as part of the cutting-edge research field known as **Causal NLP**, which explores the limits of LLMs’ fundamental reasoning abilities.

### Referenced Paper

**Can Large Language Models Infer Causation from Correlation?** (Zhijing Jin et al., 2024)

* **arXiv link**: [https://arxiv.org/pdf/2306.05836](https://arxiv.org/pdf/2306.05836)

### Focus of the Evaluation

The purpose of the referenced study is to clarify whether LLMs can evaluate causal abilities not as mere **empirical knowledge** (common sense or information learned from data), but as **pure causal inference** (logical derivation based on known procedures or formal rules, such as Spirtes 2000).

* Many previous studies have treated causal inference as an extension of empirical knowledge, depending on the quality and coverage of training data.
* This study asks whether LLMs can **logically derive causal relationships solely based on the given rules of correlation**.

### Findings from Previous Studies on LLM Reasoning Abilities

In the referenced paper, the evaluation dataset **CORR2CAUSE** was defined and constructed to explore one aspect of LLM reasoning ability — pure causal inference.

* **Pre–fine-tuning performance**: Even the best-performing model (BART MNLI) scored an F1 of **33.38%**, leading to the conclusion that pure causal inference abilities were nearly absent.
* **Limitations after fine-tuning**: Although fine-tuning significantly improved performance, the improvement was limited to in-distribution data similar to the training data. The problem of **out-of-distribution generalization** persisted (e.g., a model trained on correlations like “ice and water” fails to infer causal relationships in unseen domains like “internet use and health issues”).

## Evaluation Tasks and Methods

To distinguish causal relationships from correlational ones, we defined four tasks based on 50 scenarios (Japanese, English, Russian) containing six types of gold labels.

* **Causal types (4 classes)**: `Is-Parent` (direct cause), `Is-Ancestor` (indirect cause), `Is-Child` (direct effect), `Is-Descendant` (indirect effect)
* **Correlational types (2 classes)**: `Has-Collider` (common effect), `Has-Confounder` (common cause)

| Task                            | Input                | Output Label                                       | Purpose / Evaluation Focus                                               |
| :------------------------------ | :------------------- | :------------------------------------------------- | :----------------------------------------------------------------------- |
| **Task 1** (Scenario-only)      | Scenario (text) only | Causal / Correlational / Other (3 classes)         | Ability to classify relationship types from sentence tone and structure. |
| **Task 2** (Keyword Extraction) | Scenario (text)      | Two most important noun phrases (variables i, j)   | Ability to extract variables (keywords).                                 |
| **Task 3** (3-class)            | Variables i, j       | Causal / Correlational / Other (3 classes)         | Understanding logical relationships when variables are explicit.         |
| **Task 4** (4-class)            | Variables i, j       | Is-Parent / Is-Ancestor / Is-Child / Is-Descendant | Ability to distinguish detailed causal structure (direct/indirect).      |

※ Task 3 and 4 each have two evaluation settings:
**Oracle** (using gold keywords) and **E2E** (End-to-End, using keywords extracted in Task 2).

## Models and Environment

This evaluation uses the following two models:

| Item                    | Details                    |
| :---------------------- | :------------------------- |
| **Evaluation Models**   | Gemini 2.5 Pro, gpt-5-chat |
| **Languages Evaluated** | Japanese, English, Russian |

## Execution Results (Gemini 2.5 Pro / gpt-5-chat)

Results for both models across three languages are shown below.

### 1. Japanese Results (Total items: 50, Task 4 items: 34)

| Model              | Task 1      | Task 2     | Task 3 (Oracle) | Task 3 (E2E) | Task 4 (Oracle) | Task 4 (E2E) |
| :----------------- | :---------- | :--------- | :-------------- | :----------- | :-------------- | :----------- |
| **Gemini 2.5 Pro** | **100.00%** | **36.00%** | 66.00%          | **84.00%**   | **70.59%**      | **47.06%**   |
| **GPT-5 Chat**     | 96.00%      | 30.00%     | **94.00%**      | 70.00%       | 55.88%          | 41.18%       |

### 2. English Results (Total items: 50, Task 4 items: 34)

| Model              | Task 1      | Task 2     | Task 3 (Oracle) | Task 3 (E2E) | Task 4 (Oracle) | Task 4 (E2E) |
| :----------------- | :---------- | :--------- | :-------------- | :----------- | :-------------- | :----------- |
| **Gemini 2.5 Pro** | **100.00%** | 4.00%      | 66.00%          | **78.00%**   | **73.53%**      | 38.24%       |
| **GPT-5 Chat**     | 92.00%      | **20.00%** | **94.00%**      | 64.00%       | 58.82%          | 38.24%       |

### 3. Russian Results (Total items: 50, Task 4 items: 34)

| Model              | Task 1 | Task 2     | Task 3 (Oracle) | Task 3 (E2E) | Task 4 (Oracle) | Task 4 (E2E) |
| :----------------- | :----- | :--------- | :-------------- | :----------- | :-------------- | :----------- |
| **Gemini 2.5 Pro** | 98.00% | 2.00%      | 76.00%          | **72.00%**   | 67.65%          | **41.18%**   |
| **GPT-5 Chat**     | 88.00% | **16.00%** | **88.00%**      | 68.00%       | 58.52%          | 41.18%       |

## Discussion and Key Findings

From the comparison of both models and consideration of prior research, the following important findings were obtained:

1. **Difficulty of keyword extraction and the gap with logical understanding**

   * Despite low accuracy in Task 2 (keyword extraction), high accuracy in Task 3 (E2E) indicates that LLMs are **not good at formal variable extraction (short noun phrases)**, but can distinguish **logical relationships from contextual understanding**.
2. **Differences in model characteristics**

   * **Gemini 2.5 Pro** tends to be weaker than GPT-5 in keyword extraction (Task 2), but is better in **logical relationship understanding (Task 3 E2E)**, which is one level more difficult. It is especially concluded that **Gemini has higher Japanese comprehension ability**.
   * **GPT-5 Chat** shows extremely high accuracy in Task 3 when correct keywords are provided, indicating solid understanding of logical relationships.
3. **Detailed causal-structure classification remains difficult**

   * Task 4 (4-class causal structure) E2E scores do not exceed 47.06% for any model or language, showing that distinguishing types of causal relationships is **not yet at a practical level**.
4. **Generalization remains a challenge**

   * Consistent with prior research, the benefits of fine-tuning are limited to in-distribution data, and issues of **out-of-distribution generalization** remain.

If you plan to cite, reuse, or consider commercial use of all or part of the experimental results or code, please contact the following address to confirm proper rights attribution and usage conditions.

For academic use, citation is sufficient.

Contact: **[mayhawks9@gmail.com](mailto:mayhawks9@gmail.com)**

