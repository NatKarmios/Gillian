open Cmdliner

module Make
    (ID : Init_data.S)
    (PC : ParserAndCompiler.S with type init_data = ID.t)
    (Verification : Verifier.S
                      with type annot = PC.Annot.t
                       and type SPState.init_data = ID.t) =
struct
  let grok () =
    let json =
      Yojson.Safe.from_string
        {|{
            "preds": [],
            "state": [
                [
                    [
                        "_$l_0",
                        [
                            "Tree",
                            {
                                "bounds": [
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "0"
                                        ]
                                    ],
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "8"
                                        ]
                                    ]
                                ],
                                "root": {
                                    "children": null,
                                    "last_path": [
                                        "Here"
                                    ],
                                    "node": [
                                        "MemVal",
                                        {
                                            "exact_perm": [
                                                "Freeable"
                                            ],
                                            "mem_val": [
                                                "Single",
                                                {
                                                    "chunk": [
                                                        "U64"
                                                    ],
                                                    "value": [
                                                        "LVar",
                                                        "#self"
                                                    ]
                                                }
                                            ],
                                            "min_perm": [
                                                "Freeable"
                                            ]
                                        }
                                    ],
                                    "span": [
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "0"
                                            ]
                                        ],
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "8"
                                            ]
                                        ]
                                    ]
                                }
                            }
                        ]
                    ],
                    [
                        "_$l_1",
                        [
                            "Tree",
                            {
                                "bounds": [
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "0"
                                        ]
                                    ],
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "16"
                                        ]
                                    ]
                                ],
                                "root": {
                                    "children": null,
                                    "last_path": null,
                                    "node": [
                                        "MemVal",
                                        {
                                            "exact_perm": [
                                                "Freeable"
                                            ],
                                            "mem_val": [
                                                "Poisoned",
                                                [
                                                    "Totally"
                                                ]
                                            ],
                                            "min_perm": [
                                                "Freeable"
                                            ]
                                        }
                                    ],
                                    "span": [
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "0"
                                            ]
                                        ],
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "16"
                                            ]
                                        ]
                                    ]
                                }
                            }
                        ]
                    ],
                    [
                        "_$l_2",
                        [
                            "Tree",
                            {
                                "bounds": [
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "0"
                                        ]
                                    ],
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "8"
                                        ]
                                    ]
                                ],
                                "root": {
                                    "children": null,
                                    "last_path": null,
                                    "node": [
                                        "MemVal",
                                        {
                                            "exact_perm": [
                                                "Freeable"
                                            ],
                                            "mem_val": [
                                                "Poisoned",
                                                [
                                                    "Totally"
                                                ]
                                            ],
                                            "min_perm": [
                                                "Freeable"
                                            ]
                                        }
                                    ],
                                    "span": [
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "0"
                                            ]
                                        ],
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "8"
                                            ]
                                        ]
                                    ]
                                }
                            }
                        ]
                    ],
                    [
                        "_$l_3",
                        [
                            "Tree",
                            {
                                "bounds": [
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "0"
                                        ]
                                    ],
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "8"
                                        ]
                                    ]
                                ],
                                "root": {
                                    "children": null,
                                    "last_path": null,
                                    "node": [
                                        "MemVal",
                                        {
                                            "exact_perm": [
                                                "Freeable"
                                            ],
                                            "mem_val": [
                                                "Poisoned",
                                                [
                                                    "Totally"
                                                ]
                                            ],
                                            "min_perm": [
                                                "Freeable"
                                            ]
                                        }
                                    ],
                                    "span": [
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "0"
                                            ]
                                        ],
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "8"
                                            ]
                                        ]
                                    ]
                                }
                            }
                        ]
                    ],
                    [
                        "_$l_5",
                        [
                            "Tree",
                            {
                                "bounds": null,
                                "root": {
                                    "children": [
                                        {
                                            "children": null,
                                            "last_path": [
                                                "Here"
                                            ],
                                            "node": [
                                                "MemVal",
                                                {
                                                    "exact_perm": [
                                                        "Freeable"
                                                    ],
                                                    "mem_val": [
                                                        "Single",
                                                        {
                                                            "chunk": [
                                                                "U32"
                                                            ],
                                                            "value": [
                                                                "Lit",
                                                                [
                                                                    "Int",
                                                                    "0"
                                                                ]
                                                            ]
                                                        }
                                                    ],
                                                    "min_perm": [
                                                        "Freeable"
                                                    ]
                                                }
                                            ],
                                            "span": [
                                                [
                                                    "LVar",
                                                    "_lvar_10"
                                                ],
                                                [
                                                    "BinOp",
                                                    [
                                                        "LVar",
                                                        "_lvar_10"
                                                    ],
                                                    [
                                                        "IPlus"
                                                    ],
                                                    [
                                                        "Lit",
                                                        [
                                                            "Int",
                                                            "4"
                                                        ]
                                                    ]
                                                ]
                                            ]
                                        },
                                        {
                                            "children": null,
                                            "last_path": [
                                                "Here"
                                            ],
                                            "node": [
                                                "MemVal",
                                                {
                                                    "exact_perm": [
                                                        "Freeable"
                                                    ],
                                                    "mem_val": [
                                                        "Poisoned",
                                                        [
                                                            "Totally"
                                                        ]
                                                    ],
                                                    "min_perm": [
                                                        "Freeable"
                                                    ]
                                                }
                                            ],
                                            "span": [
                                                [
                                                    "BinOp",
                                                    [
                                                        "Lit",
                                                        [
                                                            "Int",
                                                            "4"
                                                        ]
                                                    ],
                                                    [
                                                        "IPlus"
                                                    ],
                                                    [
                                                        "LVar",
                                                        "_lvar_10"
                                                    ]
                                                ],
                                                [
                                                    "BinOp",
                                                    [
                                                        "Lit",
                                                        [
                                                            "Int",
                                                            "12"
                                                        ]
                                                    ],
                                                    [
                                                        "IPlus"
                                                    ],
                                                    [
                                                        "LVar",
                                                        "_lvar_10"
                                                    ]
                                                ]
                                            ]
                                        }
                                    ],
                                    "last_path": [
                                        "Left"
                                    ],
                                    "node": [
                                        "MemVal",
                                        {
                                            "exact_perm": [
                                                "Freeable"
                                            ],
                                            "mem_val": [
                                                "Poisoned",
                                                [
                                                    "Partially"
                                                ]
                                            ],
                                            "min_perm": [
                                                "Freeable"
                                            ]
                                        }
                                    ],
                                    "span": [
                                        [
                                            "LVar",
                                            "_lvar_10"
                                        ],
                                        [
                                            "BinOp",
                                            [
                                                "Lit",
                                                [
                                                    "Int",
                                                    "12"
                                                ]
                                            ],
                                            [
                                                "IPlus"
                                            ],
                                            [
                                                "LVar",
                                                "_lvar_10"
                                            ]
                                        ]
                                    ]
                                }
                            }
                        ]
                    ]
                ],
                {
                    "conc": [
                        [
                            "temp__10",
                            [
                                "Lit",
                                [
                                    "Int",
                                    "1"
                                ]
                            ]
                        ],
                        [
                            "temp__14",
                            [
                                "Lit",
                                [
                                    "Undefined"
                                ]
                            ]
                        ],
                        [
                            "temp__12",
                            [
                                "EList",
                                []
                            ]
                        ],
                        [
                            "var_0",
                            [
                                "Lit",
                                [
                                    "Undefined"
                                ]
                            ]
                        ],
                        [
                            "var_2",
                            [
                                "Lit",
                                [
                                    "Int",
                                    "1"
                                ]
                            ]
                        ],
                        [
                            "var_4",
                            [
                                "Lit",
                                [
                                    "Undefined"
                                ]
                            ]
                        ],
                        [
                            "temp__5",
                            [
                                "Lit",
                                [
                                    "Undefined"
                                ]
                            ]
                        ]
                    ],
                    "symb": [
                        [
                            "var_7",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_2"
                                    ],
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "0"
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        [
                            "var_6",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_1"
                                    ],
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "0"
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        [
                            "var_5",
                            [
                                "EList",
                                [
                                    [
                                        "LVar",
                                        "_lvar_7"
                                    ],
                                    [
                                        "LVar",
                                        "_lvar_8"
                                    ]
                                ]
                            ]
                        ],
                        [
                            "temp__9",
                            [
                                "LVar",
                                "#self"
                            ]
                        ],
                        [
                            "temp__13",
                            [
                                "EList",
                                [
                                    [
                                        "LVar",
                                        "_lvar_7"
                                    ],
                                    [
                                        "LVar",
                                        "_lvar_8"
                                    ]
                                ]
                            ]
                        ],
                        [
                            "temp__7",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_2"
                                    ]
                                ]
                            ]
                        ],
                        [
                            "temp__4",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_0"
                                    ]
                                ]
                            ]
                        ],
                        [
                            "next",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_4"
                                    ],
                                    [
                                        "BinOp",
                                        [
                                            "Lit",
                                            [
                                                "Int",
                                                "8"
                                            ]
                                        ],
                                        [
                                            "IPlus"
                                        ],
                                        [
                                            "LVar",
                                            "_lvar_4"
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        [
                            "temp__11",
                            [
                                "LVar",
                                "#self"
                            ]
                        ],
                        [
                            "temp__8",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_3"
                                    ]
                                ]
                            ]
                        ],
                        [
                            "temp__6",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_1"
                                    ]
                                ]
                            ]
                        ],
                        [
                            "var_8",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_3"
                                    ],
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "0"
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        [
                            "temp__15",
                            [
                                "EList",
                                [
                                    [
                                        "LVar",
                                        "_lvar_7"
                                    ],
                                    [
                                        "LVar",
                                        "_lvar_8"
                                    ]
                                ]
                            ]
                        ],
                        [
                            "self",
                            [
                                "EList",
                                [
                                    [
                                        "ALoc",
                                        "_$l_0"
                                    ],
                                    [
                                        "Lit",
                                        [
                                            "Int",
                                            "0"
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                },
                [
                    [
                        "Eq",
                        [
                            "LVar",
                            "#self"
                        ],
                        [
                            "EList",
                            [
                                [
                                    "ALoc",
                                    "_$l_5"
                                ],
                                [
                                    "LVar",
                                    "_lvar_10"
                                ]
                            ]
                        ]
                    ],
                    [
                        "Eq",
                        [
                            "LVar",
                            "#sz"
                        ],
                        [
                            "Lit",
                            [
                                "Int",
                                "0"
                            ]
                        ]
                    ],
                    [
                        "Eq",
                        [
                            "LVar",
                            "_lvar_9"
                        ],
                        [
                            "ALoc",
                            "_$l_5"
                        ]
                    ],
                    [
                        "ILessEq",
                        [
                            "Lit",
                            [
                                "Int",
                                "0"
                            ]
                        ],
                        [
                            "UnOp",
                            [
                                "LstLen"
                            ],
                            [
                                "LVar",
                                "#self"
                            ]
                        ]
                    ]
                ],
                [
                    [
                        "_lvar_9",
                        [
                            "ObjectType"
                        ]
                    ],
                    [
                        "#self",
                        [
                            "ListType"
                        ]
                    ],
                    [
                        "_lvar_10",
                        [
                            "IntType"
                        ]
                    ],
                    [
                        "#sz",
                        [
                            "IntType"
                        ]
                    ]
                ],
                [
                    "#self",
                    "#sz"
                ]
            ],
            "variants": [
                [
                    "list_length",
                    null
                ]
            ]
        }|}
    in
    match Verification.SPState.of_yojson json with
    | Error s -> Fmt.failwith "Error: %s" s
    | Ok state ->
        let msg = Fmt.str "%a" Verification.SPState.pp state in
        Fmt.pr "%s" msg

  let grok_t = Term.(const grok $ const ())
  let grok_cmd = Cmd.v (Cmd.info "grok") grok_t
  let cmds = [ grok_cmd ]
end
