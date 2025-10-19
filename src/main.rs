#![feature(stmt_expr_attributes)]
#![allow(internal_features)] // what is the point of this flag? The only way to use internal_features right now is to explicitly opt-in
#![feature(fmt_internals)]
use ast::tokens_into_ast;
use clap::Parser;
use clap_stdin::MaybeStdin;
use color_eyre::eyre::Result;
use lexer::str_into_tokens;
use tree_kinds::TreeKind;

mod ast;
mod lexer;
pub mod tree_kinds;
pub mod utils;

#[derive(Debug, Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
	s: MaybeStdin<String>,

	/// Allow parsing structures like `explanation nesting level: key: value`
	///NB: Adds `n/2` for each encountered colon (could be implemented better, but eh)
	/// # Ex
	/// ```sh
	/// some explanation: another explanation: key: value""" | prettify_log - --maybe-colon-nested
	/// ```
	#[arg(long)]
	maybe_colon_nested: bool,
}

fn main() {
	color_eyre::install().unwrap();
	let cli = Cli::parse();
	let input = format!("{}", cli.s);

	let parsed = match parse(input, cli.maybe_colon_nested) {
		Ok(ast) => ast,
		Err(e) => {
			eprintln!("Error: {e}");
			std::process::exit(1);
		}
	};
	println!("{parsed}");
}

fn parse(input: String, maybe_colon_nested: bool) -> Result<TreeKind> {
	let mut tokens = str_into_tokens(input)?;
	let ast = match maybe_colon_nested {
		#[allow(clippy::never_loop)]
		true => loop {
			match tokens_into_ast(tokens.clone()) {
				Ok(ast) => break ast,
				Err(e) => {
					let i = tokens.iter().position(|t| matches!(t, lexer::Token::InnerDelim));
					if let Some(i) = i {
						tokens = tokens[i + 1..].to_vec();
					} else {
						return Err(e);
					}
				}
			}
		},
		false => tokens_into_ast(tokens)?,
	};
	Ok(ast)
}
