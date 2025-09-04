# From messy to meaningful data with LLMs

This repo includes the data, code, and slides for my post::conf(2025) talk.

## API key setup

(From a Posit [blog post](https://posit.co/blog/generate-data-with-an-llm-and-ellmer/#setup) by Sara Altman.)

First, we need to install the necessary packages and set up API keys. You’ll need:

-   [ellmer](https://ellmer.tidyverse.org/), which simplifies the process of interacting with LLMs from R and

-   [usethis](https://usethis.r-lib.org/), which we’ll use to set up the API keys.

```         
install.packages(c("ellmer", "usethis"))
```

Next, add your API key(s) to your `.Renviron` file. You can open your `.Renviron` for editing with `usethis::edit_r_environ()`.

You can choose the LLM that you want to work with. ellmer includes functions for working with OpenAI, Anthropic, Gemini, and other providers. You can see a full list of supported providers [here](#0).

Add your desired API key(s) to your `.Renviron`, for example:

```         
OPENAI_API_KEY=my-api-key-openai-uejkK92
ANTHROPIC_API_KEY=api-key-anthropic-nxue0
GOOGLE_API_KEY=api-key-google-palw2n
```

For selecting a model, see this [list](https://docs.anthropic.com/en/docs/about-claude/models/overview) of Anthropic model names and features.
